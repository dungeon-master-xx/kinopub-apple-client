//
//  MediaLibraryStore.swift
//  KinoPubAppleClient
//
//  Single client-side source of truth for an item's "library" state, so the UI reflects intent
//  instantly and survives offline/laggy server responses instead of re-querying on every screen:
//   • bookmark-folder membership (which folders contain an item) — owned, optimistic, persisted
//   • watchlist membership — owned, optimistic, persisted
//   • download status (downloaded / downloading / none) — façade over the existing download stores
//   • watch progress — delegated to LocalWatchProgressStore
//
//  Owns only the genuinely-missing optimistic bits (bookmarks + watchlist). Downloads and progress
//  already have working reactive stores, so we aggregate rather than duplicate them — one object the
//  UI can observe and ask, with no second source of truth.
//

import Foundation
import Combine
import KinoPubBackend
import KinoPubKit

/// Not `@MainActor` so it can be built inside `AppContext.shared`'s nonisolated initializer; all
/// mutations are invoked from the main thread (views / @MainActor models) and the download republish
/// sinks deliver on main, so `@Published` updates stay main-thread.
final class MediaLibraryStore: ObservableObject {

  enum DownloadStatus: Equatable {
    case none
    case downloading(Double)   // 0...1
    case downloaded
  }

  // MARK: - Owned optimistic state (persisted)

  private struct Record: Codable {
    var bookmarkFolderIds: [Int] = []
    var inWatchlist: Bool?
  }

  @Published private var records: [Int: Record] = [:]
  /// Optimistic "watched" overrides — win over the server's value until a fetch reconciles them away
  /// (so the server can still drive auto-watched/cross-device changes). Movie keyed by item id,
  /// episode keyed by episode id.
  @Published private var movieWatchedOverride: [Int: Bool] = [:]
  @Published private var episodeWatchedOverride: [Int: Bool] = [:]
  /// Remembered audio track (озвучка) per item/series id. Stores AVFoundation's own identifiers so
  /// re-selection round-trips reliably, independent of kino.pub's audios↔HLS mapping.
  @Published private var audioPreferences: [Int: AudioPreference] = [:]

  /// Session cache of the user's bookmark folders, so screens don't re-fetch on every appearance.
  @Published private(set) var bookmarkFolders: [Bookmark] = []
  private var bookmarkFoldersLoaded = false
  private var bookmarkFoldersLoading = false

  /// In-memory index of completed downloads ("id|video|season") so per-card status checks are O(1)
  /// instead of reading plists on every render. Rebuilt whenever the download managers change.
  private var downloadedKeys: Set<String> = []

  /// A remembered audio-track selection, captured from the AVPlayer's own media-selection option.
  struct AudioPreference: Codable, Equatable {
    var displayName: String
    var languageTag: String?
    var index: Int
  }

  /// On-disk shape (single file so all owned state persists together).
  private struct Persisted: Codable {
    var records: [Int: Record] = [:]
    var movieWatched: [Int: Bool] = [:]
    var episodeWatched: [Int: Bool] = [:]
    var audioPreferences: [Int: AudioPreference] = [:]
  }

  // MARK: - Façade dependencies (not owned — queried live)

  private let downloadManager: DownloadManager<DownloadMeta>
  private let hlsDownloadManager: HLSAssetDownloadManager
  private let hlsStore: HLSDownloadsStore
  private let downloadedFilesDatabase: DownloadedFilesDatabase<DownloadMeta>
  private let progressStore: LocalWatchProgressStore
  private let actionsService: UserActionsService

  private let fileURL: URL
  private var cancellables = Set<AnyCancellable>()

  init(downloadManager: DownloadManager<DownloadMeta>,
       hlsDownloadManager: HLSAssetDownloadManager,
       hlsStore: HLSDownloadsStore,
       downloadedFilesDatabase: DownloadedFilesDatabase<DownloadMeta>,
       progressStore: LocalWatchProgressStore,
       actionsService: UserActionsService) {
    self.downloadManager = downloadManager
    self.hlsDownloadManager = hlsDownloadManager
    self.hlsStore = hlsStore
    self.downloadedFilesDatabase = downloadedFilesDatabase
    self.progressStore = progressStore
    self.actionsService = actionsService
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    fileURL = directory.appendingPathComponent("media_library.json")
    load()
    rebuildDownloadedIndex()

    // Republish the download managers' changes so any view observing the library updates live as
    // downloads progress/complete — mirrors what DownloadsCatalog does for the Downloads tab. Also
    // rebuild the completed-download index so per-card "downloaded" checks stay current and cheap.
    downloadManager.$activeDownloads
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in self?.rebuildDownloadedIndex(); self?.objectWillChange.send() }
      .store(in: &cancellables)
    hlsDownloadManager.objectWillChange
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in self?.rebuildDownloadedIndex(); self?.objectWillChange.send() }
      .store(in: &cancellables)
  }

  // MARK: - Bookmarks (folder membership)

  func bookmarkFolderIds(itemId: Int) -> Set<Int> {
    Set(records[itemId]?.bookmarkFolderIds ?? [])
  }

  func isBookmarked(itemId: Int, folderId: Int) -> Bool {
    records[itemId]?.bookmarkFolderIds.contains(folderId) ?? false
  }

  func isInAnyBookmarkFolder(itemId: Int) -> Bool {
    !(records[itemId]?.bookmarkFolderIds.isEmpty ?? true)
  }

  /// Seed an item's library state from authoritative server data the first time we see it, without
  /// clobbering optimistic edits the user may have made (which is why a later refetch won't reset it).
  func seedIfAbsent(itemId: Int, folderIds: [Int], inWatchlist: Bool) {
    guard records[itemId] == nil else { return }
    records[itemId] = Record(bookmarkFolderIds: folderIds.sorted(), inWatchlist: inWatchlist)
    persist()
  }

  /// Optimistically flip membership for a folder; returns the new state (true = now in folder).
  @discardableResult
  func toggleBookmark(itemId: Int, folderId: Int) -> Bool {
    var set = bookmarkFolderIds(itemId: itemId)
    let isOn = !set.contains(folderId)
    if isOn { set.insert(folderId) } else { set.remove(folderId) }
    setBookmark(itemId: itemId, folderId: folderId, isOn: isOn)
    return isOn
  }

  /// Force a membership value (used to revert after a failed server call).
  func setBookmark(itemId: Int, folderId: Int, isOn: Bool) {
    var record = records[itemId] ?? Record()
    var set = Set(record.bookmarkFolderIds)
    if isOn { set.insert(folderId) } else { set.remove(folderId) }
    record.bookmarkFolderIds = set.sorted()
    records[itemId] = record
    persist()
  }

  // MARK: - Watchlist

  /// Optimistic watchlist membership, or nil if unknown (caller falls back to the server flag).
  func inWatchlist(itemId: Int) -> Bool? {
    records[itemId]?.inWatchlist
  }

  func seedWatchlist(itemId: Int, value: Bool) {
    var record = records[itemId] ?? Record()
    record.inWatchlist = value
    records[itemId] = record
    persist()
  }

  func setWatchlist(itemId: Int, value: Bool) {
    seedWatchlist(itemId: itemId, value: value)
  }

  // MARK: - Watched (optimistic override over the server value)

  /// Effective watched state for a movie: optimistic override if present, else the server's value.
  func movieWatched(itemId: Int, serverWatched: Bool) -> Bool {
    movieWatchedOverride[itemId] ?? serverWatched
  }

  /// Effective watched state for an episode: optimistic override if present, else the server's value.
  func episodeWatched(episodeId: Int, serverWatched: Bool) -> Bool {
    episodeWatchedOverride[episodeId] ?? serverWatched
  }

  func setMovieWatched(itemId: Int, value: Bool) {
    movieWatchedOverride[itemId] = value
    persist()
  }

  func setEpisodeWatched(episodeId: Int, value: Bool) {
    episodeWatchedOverride[episodeId] = value
    persist()
  }

  /// Drop optimistic overrides that fresh server data now confirms, so the server drives again;
  /// overrides that still differ (a toggle still in flight) are kept.
  func reconcileWatched(movieItemId: Int, serverMovieWatched: Bool?, episodes: [(id: Int, watched: Bool)]) {
    var changed = false
    if let server = serverMovieWatched, movieWatchedOverride[movieItemId] == server {
      movieWatchedOverride[movieItemId] = nil
      changed = true
    }
    for episode in episodes where episodeWatchedOverride[episode.id] == episode.watched {
      episodeWatchedOverride[episode.id] = nil
      changed = true
    }
    if changed { persist() }
  }

  // MARK: - Downloads (façade over existing stores/managers)

  func downloadStatus(itemId: Int, video: Int?, season: Int?) -> DownloadStatus {
    if isDownloaded(itemId: itemId, video: video, season: season) { return .downloaded }
    if let progress = activeDownloadProgress(itemId: itemId, video: video, season: season) {
      return .downloading(progress)
    }
    return .none
  }

  func isDownloaded(itemId: Int, video: Int?, season: Int?) -> Bool {
    downloadedKeys.contains(Self.downloadKey(itemId, video, season))
  }

  /// Whether the title has ANY completed download (any episode/video) — for poster cards in lists,
  /// where the specific video/season isn't known.
  func isDownloadedAny(itemId: Int) -> Bool {
    let prefix = "\(itemId)|"
    return downloadedKeys.contains { $0.hasPrefix(prefix) }
  }

  /// Whether the title has ANY in-flight download right now (any episode/video).
  func isDownloadingAny(itemId: Int) -> Bool {
    if hlsDownloadManager.activeDownloads.contains(where: { $0.meta.id == itemId }) { return true }
    return downloadManager.activeDownloads.values.contains(where: { $0.metadata.id == itemId })
  }

  private static func downloadKey(_ id: Int, _ video: Int?, _ season: Int?) -> String {
    "\(id)|\(video.map(String.init) ?? "-")|\(season.map(String.init) ?? "-")"
  }

  /// Rebuild the completed-download index from the HLS + mp4 stores (cheap plist reads, done once
  /// per download-state change rather than per card per render).
  private func rebuildDownloadedIndex() {
    var keys = Set<String>()
    for asset in hlsStore.readData() where asset.fileExists {
      keys.insert(Self.downloadKey(asset.meta.id, asset.meta.metadata.video, asset.meta.metadata.season))
    }
    for file in (downloadedFilesDatabase.readData() ?? [])
    where FileManager.default.fileExists(atPath: file.localFileURL.path) {
      keys.insert(Self.downloadKey(file.metadata.id, file.metadata.metadata.video, file.metadata.metadata.season))
    }
    downloadedKeys = keys
  }

  /// Live progress [0,1] of an in-flight download for this item/episode, or nil if none.
  func activeDownloadProgress(itemId: Int, video: Int?, season: Int?) -> Double? {
    if let hls = hlsDownloadManager.activeDownloads.first(where: {
      $0.meta.id == itemId && $0.meta.metadata.video == video && $0.meta.metadata.season == season
    }) {
      return Double(hls.progress)
    }
    if let mp4 = downloadManager.activeDownloads.values.first(where: {
      $0.metadata.id == itemId && $0.metadata.metadata.video == video && $0.metadata.metadata.season == season
    }) {
      return Double(mp4.progress)
    }
    return nil
  }

  // MARK: - Watch progress (delegated to LocalWatchProgressStore)

  func watchProgress(itemId: Int, season: Int?, episode: Int?) -> Double? {
    progressStore.entry(forId: itemId, season: season, episode: episode)?.progress
  }

  // MARK: - Bookmark folders (session cache)

  /// Load the user's bookmark folders once per session; subsequent calls are no-ops. Screens read
  /// `bookmarkFolders` instead of fetching on every appearance.
  @MainActor
  func loadBookmarkFoldersIfNeeded() async {
    guard !bookmarkFoldersLoaded, !bookmarkFoldersLoading else { return }
    await reloadBookmarkFolders()
  }

  /// Force a fresh fetch (e.g. pull-to-refresh on the Bookmarks tab, or after creating a folder).
  @MainActor
  func reloadBookmarkFolders() async {
    guard !bookmarkFoldersLoading else { return }
    bookmarkFoldersLoading = true
    defer { bookmarkFoldersLoading = false }
    do {
      bookmarkFolders = try await actionsService.fetchBookmarks()
      bookmarkFoldersLoaded = true
    } catch {
      // Leave any previously cached folders in place; callers surface their own errors if needed.
    }
  }

  // MARK: - Audio track preference (озвучка) per item/series id

  func audioPreference(itemId: Int) -> AudioPreference? {
    audioPreferences[itemId]
  }

  func setAudioPreference(itemId: Int, _ preference: AudioPreference) {
    guard audioPreferences[itemId] != preference else { return }  // avoid churn on the 10s capture
    audioPreferences[itemId] = preference
    persist()
  }

  // MARK: - Persistence

  private func load() {
    guard let data = try? Data(contentsOf: fileURL),
          let decoded = try? JSONDecoder().decode(Persisted.self, from: data) else { return }
    records = decoded.records
    movieWatchedOverride = decoded.movieWatched
    episodeWatchedOverride = decoded.episodeWatched
    audioPreferences = decoded.audioPreferences
  }

  private func persist() {
    let snapshot = Persisted(records: records,
                             movieWatched: movieWatchedOverride,
                             episodeWatched: episodeWatchedOverride,
                             audioPreferences: audioPreferences)
    guard let data = try? JSONEncoder().encode(snapshot) else { return }
    try? data.write(to: fileURL, options: .atomic)
  }
}

// MARK: - AppContext access

protocol MediaLibraryProvider {
  var libraryState: MediaLibraryStore { get }
}
