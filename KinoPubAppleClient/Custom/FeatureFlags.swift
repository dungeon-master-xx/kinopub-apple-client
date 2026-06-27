//
//  FeatureFlags.swift
//  KinoPubAppleClient
//
//  Lightweight compile-time flags for gating work that isn't ready to ship to users yet.
//

import Foundation

enum FeatureFlags {
  /// Comments on a title's detail page. Kept off until the live `GET /v1/items/comments` response
  /// shape is verified against a real account — the implementation and its decoder are complete and
  /// tested, but couldn't be confirmed end-to-end yet, so we don't surface a possibly-empty screen.
  static let comments = false

  /// 3D (stereoscopic) playback. OFF: `AVVideoComposition`'s SBS/OU/anaglyph reshaping doesn't
  /// reliably apply to kino.pub's streams (shows a doubled/packed image), so the detail-page mode
  /// picker and the player composition are hidden until reworked (likely a Metal /
  /// `AVPlayerItemVideoOutput` renderer instead of `AVVideoComposition`).
  static let threeDEnabled = false
}
