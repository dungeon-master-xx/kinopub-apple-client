//
//  VoteRequest.swift
//

import Foundation

/// Up-votes an item (`like=1`) or removes the vote (`like=0`) — `GET /v1/items/vote?id=&like=`.
public struct VoteRequest: Endpoint {

  public var id: Int
  public var like: Int

  public init(id: Int, like: Int) {
    self.id = id
    self.like = like
  }

  public var path: String { "/v1/items/vote" }
  public var method: String { "GET" }
  public var parameters: [String: Any]? { ["id": id, "like": like] }
  public var headers: [String: String]? { nil }
  public var forceSendAsGetParams: Bool { true }
}
