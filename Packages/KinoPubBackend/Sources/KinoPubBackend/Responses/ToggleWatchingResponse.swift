//
//  ToggleWatchingResponse.swift
//
//
//  Created by Kirill Kunst on 11.11.2023.
//

import Foundation

public struct ToggleWatchingResponse: Codable {
  public let status: Int?
  public let watched: Int?
  // NOTE: the API returns `watching` as an OBJECT (`{"status":1}`), not a Bool. Decoding it as a
  // Bool used to throw, making every watched / watchlist toggle silently fail (the action reverted
  // its optimistic state). We don't use the field, so it's dropped — Codable ignores unknown keys.
}
