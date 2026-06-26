//
//  ActorImageProvider.swift
//  KinoPubAppleClient
//
//  kino.pub serves actor/director portraits from its own CDN, keyed by the MD5 of the (Russian) name
//  — the exact scheme the kpapp.link web app uses (verified: m.pushbr.com/actors/<md5(name)>.jpg).
//  This replaces the previous TMDB lookup: no API key, no network round-trip to resolve a name, and
//  it covers every person kino.pub knows. Missing photos return HTTP 403, so callers fall back to a
//  placeholder via the async image loader.
//

import Foundation
import CryptoKit

enum ActorImageProvider {
  /// Portrait URL for a cast/crew member by their exact name string (as returned by kino.pub).
  static func photoURL(for name: String) -> URL? {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    let digest = Insecure.MD5.hash(data: Data(trimmed.utf8))
    let hex = digest.map { String(format: "%02x", $0) }.joined()
    return URL(string: "https://m.pushbr.com/actors/\(hex).jpg")
  }

  /// Convenience for views that hold the name as a `String` and need an optional URL string.
  static func photoURLString(for name: String) -> String? {
    photoURL(for: name)?.absoluteString
  }
}
