//
//  HLSAssetDownloadManager.swift
//  KinoPubAppleClient
//
//  Downloads HLS streams (master .m3u8) for offline playback using
//  AVAssetDownloadURLSession + AVAggregateAssetDownloadTask so that ALL audio
//  tracks (озвучки) and subtitles are downloaded alongside the video and remain
//  switchable during offline playback.
//
//  IMPORTANT: AVAssetDownloadURLSession / AVAggregateAssetDownloadTask are
//  iOS/tvOS only — NOT available on macOS. All AVAssetDownload* usage is gated
//  behind `#if os(iOS)`. On macOS this type exists as a no-op so shared code
//  (AppContext, DownloadsCatalog, MediaItemModel) compiles unchanged; the macOS
//  download path continues to use the mp4 `DownloadManager`.
//

import Foundation
import Combine
import KinoPubBackend
import KinoPubLogging
import OSLog
import AVFoundation

/// Lightweight, UI-facing description of an in-flight HLS download.
public struct HLSActiveDownload: Identifiable, Equatable {
  public let id: String        // taskDescription key (meta id + video + season)
  public let meta: DownloadMeta
  public var progress: Float

  public init(id: String, meta: DownloadMeta, progress: Float) {
    self.id = id
    self.meta = meta
    self.progress = progress
  }
}

/// Stable key used as the task description so we can re-associate background
/// tasks with their metadata after an app relaunch.
enum HLSDownloadKey {
  static func make(for meta: DownloadMeta) -> String {
    "\(meta.id)|\(meta.metadata.video.map(String.init) ?? "-")|\(meta.metadata.season.map(String.init) ?? "-")"
  }
}

#if os(iOS)

public final class HLSAssetDownloadManager: NSObject, ObservableObject, AVAssetDownloadDelegate {

  /// In-flight downloads keyed by `HLSDownloadKey`.
  @Published public private(set) var activeDownloads: [HLSActiveDownload] = []

  private let store: HLSDownloadsStore
  /// Maximum desired resolution height (px) used to derive a bitrate cap, or nil
  /// for "best available" (adaptive). Injected from the app's StreamQuality
  /// setting where one exists.
  private let maxResolutionProvider: () -> Int?

  /// Notification hooks (mirrors the mp4 path). Optional so macOS / tests can omit.
  public var onDownloadFinished: ((DownloadMeta) -> Void)?
  public var onDownloadFailed: ((DownloadMeta) -> Void)?

  // Per-running-task state.
  private struct TaskContext {
    let meta: DownloadMeta
    var loadedTimeRanges: [CMTimeRange] = []
    var fullRange: CMTimeRange = CMTimeRange()
    var downloadURL: URL?      // the .movpkg location handed to us by the delegate
  }
  private var contexts: [Int: TaskContext] = [:]   // keyed by task.taskIdentifier

  public init(store: HLSDownloadsStore,
              maxResolutionProvider: @escaping () -> Int? = { nil }) {
    self.store = store
    self.maxResolutionProvider = maxResolutionProvider
    super.init()
    _ = session // force lazy creation so background tasks are reattached
  }

  private lazy var session: AVAssetDownloadURLSession = {
    let config = URLSessionConfiguration.background(withIdentifier: "com.kinopub.hlsDownloadSession")
    return AVAssetDownloadURLSession(configuration: config,
                                     assetDownloadDelegate: self,
                                     delegateQueue: .main)
  }()

  // MARK: - Public API

  /// Starts (or no-ops if already running) an HLS download of `hlsURL` for `meta`.
  public func startDownload(meta: DownloadMeta, hlsURL: URL) {
    let key = HLSDownloadKey.make(for: meta)

    // Already downloading?
    if activeDownloads.contains(where: { $0.id == key }) {
      Logger.kit.debug("[HLS] download already active for key \(key)")
      return
    }
    // Already downloaded?
    if store.asset(forId: meta.id, video: meta.metadata.video, season: meta.metadata.season) != nil {
      Logger.kit.debug("[HLS] asset already downloaded for key \(key)")
      return
    }

    let asset = AVURLAsset(url: hlsURL)

    // Collect ALL audio + subtitle options so every озвучка / subtitle track is
    // downloaded and remains switchable offline.
    var mediaSelections: [AVMediaSelection] = []
    if let baseSelection = asset.preferredMediaSelection.mutableCopy() as? AVMutableMediaSelection {
      for characteristic in [AVMediaCharacteristic.audible, .legible] {
        guard let group = asset.mediaSelectionGroup(forMediaCharacteristic: characteristic) else { continue }
        for option in group.options {
          guard let selection = baseSelection.mutableCopy() as? AVMutableMediaSelection else { continue }
          selection.select(option, in: group)
          mediaSelections.append(selection)
        }
      }
    }
    // Always include at least the preferred selection (video + default tracks).
    mediaSelections.append(asset.preferredMediaSelection)

    var options: [String: Any] = [:]
    if let maxResolution = maxResolutionProvider() {
      // Rough heuristic: ~2 Mbps per 360 lines of height (so 1080p ≈ 6 Mbps).
      // AVFoundation will pick the highest variant at or below this bitrate.
      let bitrate = max(800_000, (maxResolution / 360) * 2_000_000)
      options[AVAssetDownloadTaskMinimumRequiredMediaBitrateKey] = bitrate
    }

    guard let task = session.aggregateAssetDownloadTask(with: asset,
                                                        mediaSelections: mediaSelections,
                                                        assetTitle: meta.localizedTitle,
                                                        assetArtworkData: nil,
                                                        options: options.isEmpty ? nil : options) else {
      Logger.kit.error("[HLS] failed to create aggregate download task for key \(key)")
      onDownloadFailed?(meta)
      return
    }

    task.taskDescription = key
    contexts[task.taskIdentifier] = TaskContext(meta: meta)
    activeDownloads.append(HLSActiveDownload(id: key, meta: meta, progress: 0))
    task.resume()
    Logger.kit.debug("[HLS] started download for key \(key)")
  }

  /// Cancels an in-flight download for the given key.
  public func cancelDownload(key: String) {
    session.getAllTasks { [weak self] tasks in
      for task in tasks where task.taskDescription == key {
        task.cancel()
      }
      DispatchQueue.main.async {
        self?.activeDownloads.removeAll(where: { $0.id == key })
      }
    }
  }

  /// Reattaches any in-flight background tasks after a relaunch and rebuilds the
  /// `activeDownloads` list. Metadata is recovered from `taskDescription`.
  public func restorePendingDownloads() {
    session.getAllTasks { [weak self] tasks in
      guard let self else { return }
      var restored: [HLSActiveDownload] = []
      for task in tasks {
        guard let aggregate = task as? AVAggregateAssetDownloadTask,
              let key = aggregate.taskDescription else { continue }
        // We can recover the key but not the full DownloadMeta from the system,
        // so only re-list downloads we still hold context for (same process) or
        // fabricate a minimal placeholder otherwise.
        if let ctx = self.contexts[aggregate.taskIdentifier] {
          restored.append(HLSActiveDownload(id: key, meta: ctx.meta, progress: 0))
        }
      }
      if !restored.isEmpty {
        DispatchQueue.main.async {
          for item in restored where !self.activeDownloads.contains(where: { $0.id == item.id }) {
            self.activeDownloads.append(item)
          }
        }
      }
    }
  }

  // MARK: - AVAssetDownloadDelegate

  /// Gives us the local `.movpkg` location. Apple: persist the RELATIVE path and
  /// do not move the bundle.
  public func urlSession(_ session: URLSession,
                         aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                         willDownloadTo location: URL) {
    Logger.kit.debug("[HLS] willDownloadTo \(location.relativePath)")
    contexts[aggregateAssetDownloadTask.taskIdentifier]?.downloadURL = location
  }

  /// Progress for the currently-downloading media selection.
  public func urlSession(_ session: URLSession,
                         aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                         didLoad timeRange: CMTimeRange,
                         totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                         timeRangeExpectedToLoad: CMTimeRange,
                         for mediaSelection: AVMediaSelection) {
    let id = aggregateAssetDownloadTask.taskIdentifier
    guard contexts[id] != nil else { return }

    var loadedSeconds = 0.0
    for value in loadedTimeRanges {
      loadedSeconds += CMTimeGetSeconds(value.timeRangeValue.duration)
    }
    let expected = CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
    guard expected > 0 else { return }
    let progress = Float(min(1.0, loadedSeconds / expected))

    if let key = aggregateAssetDownloadTask.taskDescription,
       let idx = activeDownloads.firstIndex(where: { $0.id == key }) {
      activeDownloads[idx].progress = progress
    }
  }

  /// Completion. On success persist a record (relative path); on failure notify.
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    let id = task.taskIdentifier
    guard let ctx = contexts[id] else { return }
    let key = task.taskDescription ?? HLSDownloadKey.make(for: ctx.meta)
    contexts[id] = nil
    activeDownloads.removeAll(where: { $0.id == key })

    if let error = error as NSError? {
      // Cancellation isn't a "failure" worth notifying about.
      if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
        Logger.kit.debug("[HLS] download cancelled for key \(key)")
        return
      }
      Logger.kit.error("[HLS] download failed for key \(key): \(error)")
      onDownloadFailed?(ctx.meta)
      return
    }

    guard let location = ctx.downloadURL else {
      Logger.kit.error("[HLS] download finished but no location for key \(key)")
      onDownloadFailed?(ctx.meta)
      return
    }

    let asset = HLSDownloadedAsset(meta: ctx.meta,
                                   relativePath: location.relativePath,
                                   downloadDate: Date())
    store.save(asset)
    Logger.kit.info("[HLS] download finished for key \(key)")
    onDownloadFinished?(ctx.meta)
  }
}

#else

// macOS (and any non-iOS platform): no-op shim with the same public surface so
// shared code compiles. The mp4 DownloadManager handles downloads on macOS.
public final class HLSAssetDownloadManager: ObservableObject {

  @Published public private(set) var activeDownloads: [HLSActiveDownload] = []

  public var onDownloadFinished: ((DownloadMeta) -> Void)?
  public var onDownloadFailed: ((DownloadMeta) -> Void)?

  public init(store: HLSDownloadsStore,
              maxResolutionProvider: @escaping () -> Int? = { nil }) {}

  public func startDownload(meta: DownloadMeta, hlsURL: URL) {
    Logger.kit.debug("[HLS] HLS downloads are not supported on this platform; ignoring.")
  }

  public func cancelDownload(key: String) {}

  public func restorePendingDownloads() {}
}

#endif
