//
//  ClearHistoryRequest.swift
//

import Foundation

/// Clears watch history for a media / season / item — `POST /v1/history/clear-for-<scope>?id=<id>`.
public struct ClearHistoryRequest: Endpoint {

  public enum Scope: String {
    case media = "clear-for-media"
    case season = "clear-for-season"
    case item = "clear-for-item"
  }

  public var scope: Scope
  public var id: Int

  public init(scope: Scope, id: Int) {
    self.scope = scope
    self.id = id
  }

  public var path: String { "/v1/history/\(scope.rawValue)" }
  public var method: String { "POST" }
  public var parameters: [String: Any]? { ["id": id] }
  public var headers: [String: String]? { nil }
  public var forceSendAsGetParams: Bool { true }
}
