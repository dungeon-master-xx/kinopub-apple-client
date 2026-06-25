//
//  DownloadedItemView.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 8.08.2023.
//

import Foundation
import SwiftUI
import KinoPubBackend
import KinoPubUI

public struct DownloadedItemView: View {
  
  private var mediaItem: DownloadMeta
  private var progress: Float?
  private var fileURL: URL?
  private var onDownloadStateChange: (Bool) -> Void

  public init(mediaItem: DownloadMeta,
              progress: Float?,
              fileURL: URL? = nil,
              onDownloadStateChange: @escaping (Bool) -> Void) {
    self.mediaItem = mediaItem
    self.progress = progress
    self.fileURL = fileURL
    self.onDownloadStateChange = onDownloadStateChange
  }

  /// Completed downloads have no live progress.
  private var isDownloaded: Bool { progress == nil }

  public var body: some View {
    HStack(alignment: .center) {
      image

      VStack(alignment: .leading, spacing: 4) {
        title
        subtitle
        if let detail = fileDetail {
          Text(detail)
            .lineLimit(1)
            .font(.system(size: 11.0, weight: .medium))
            .foregroundStyle(Color.KinoPub.subtitle)
        }
      }.padding(.all, 5)

      if let progress = progress, progress < 1.0 {
        Spacer()
        Text("\(Int(progress * 100))%")
          .font(.system(size: 13, weight: .semibold))
          .monospacedDigit()
          .foregroundStyle(Color.KinoPub.subtitle)
        ProgressButton(progress: progress) { state in
          onDownloadStateChange(state == .pause)
        }
        .buttonStyle(.borderless)
        .padding(.leading, 8)
        .padding(.trailing, 16)
      } else {
        Spacer()
        // Clear "downloaded" indicator for finished files.
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 20))
          .foregroundStyle(Color.KinoPub.accent)
          .padding(.trailing, 16)
      }
    }
    .padding(.vertical, 8)
  }

  /// "1080p · 1.4 GB" — quality (chosen at download) and on-disk size when available.
  private var fileDetail: String? {
    var parts: [String] = []
    if let quality = mediaItem.quality, !quality.isEmpty {
      parts.append(quality)
    }
    if let size = fileSizeString {
      parts.append(size)
    }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }

  private var fileSizeString: String? {
    guard let fileURL,
          let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
          let bytes = attrs[.size] as? Int64, bytes > 0 else { return nil }
    return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
  }
  
  var image: some View {
    CachedAsyncImage(url: URL(string: mediaItem.imageUrl)) { image in
      image.resizable()
        .renderingMode(.original)
        .posterStyle(size: .small, orientation: .vertical)
    } placeholder: {
      Color.KinoPub.skeleton
        .frame(width: PosterStyle.Size.small.width,
               height: PosterStyle.Size.small.height)
    }
    .cornerRadius(8)
  }
  
  var title: some View {
    Text(mediaItem.localizedTitle)
      .lineLimit(1)
      .font(.system(size: 14.0, weight: .medium))
      .foregroundStyle(Color.KinoPub.text)
      .padding(.bottom, 10)
  }
  
  var subtitle: some View {
    Text(mediaItem.originalTitle)
      .lineLimit(1)
      .font(.system(size: 12.0, weight: .medium))
      .foregroundStyle(Color.KinoPub.subtitle)
  }
  
}

#Preview {
  DownloadedItemView(mediaItem: DownloadMeta.make(from: DownloadableMediaItem(name: "", files: [], mediaItem: MediaItem.mock(), watchingMetadata: WatchingMetadata(id: 0, video: nil, season: nil))), progress: nil) { _ in
    
  }
}

