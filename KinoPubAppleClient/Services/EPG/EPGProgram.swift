//
//  EPGProgram.swift
//  KinoPubAppleClient
//
//  A single programme entry parsed from an XMLTV EPG feed (iptv.online).
//

import Foundation

/// One scheduled broadcast on a channel: a title and an absolute start/stop time.
struct EPGProgram: Identifiable, Hashable, Codable {
  let title: String
  let start: Date
  let stop: Date

  /// Stable within a channel's schedule (start time is unique per channel in XMLTV).
  var id: String { "\(Int(start.timeIntervalSince1970))-\(title)" }

  init(title: String, start: Date, stop: Date) {
    self.title = title
    self.start = start
    self.stop = stop
  }

  /// True while `date` falls inside the broadcast window.
  func isLive(at date: Date) -> Bool { start <= date && date < stop }

  /// Fraction elapsed at `date`, clamped to 0...1 (0 before it starts, 1 once it has ended).
  func progress(at date: Date) -> Double {
    let total = stop.timeIntervalSince(start)
    guard total > 0 else { return 0 }
    return min(1, max(0, date.timeIntervalSince(start) / total))
  }
}
