//
//  WatchingSerialsRequest.swift
//
//
//  Created by Kirill Kunst on 24.06.2026.
//

import Foundation

public struct WatchingSerialsRequest: Endpoint {

  // 0 — all unwatched serials with new episodes, 1 — only serials in the watchlist
  private var subscribed: Int?

  public init(subscribed: Int? = nil) {
    self.subscribed = subscribed
  }

  public var path: String {
    "/v1/watching/serials"
  }

  public var method: String {
    "GET"
  }

  public var parameters: [String: Any]? {
    guard let subscribed = subscribed else {
      return nil
    }
    return ["subscribed": subscribed]
  }

  public var headers: [String: String]? {
    nil
  }

  public var forceSendAsGetParams: Bool { false }
}
