//
//  GetItemFoldersRequest.swift
//

import Foundation

/// Which bookmark folders contain an item — `GET /v1/bookmarks/get-item-folders?item=<id>`.
/// Response: `{status, folders:[{id,…}]}`.
public struct GetItemFoldersRequest: Endpoint {

  public var item: Int

  public init(item: Int) {
    self.item = item
  }

  public var path: String { "/v1/bookmarks/get-item-folders" }
  public var method: String { "GET" }
  public var parameters: [String: Any]? { ["item": item] }
  public var headers: [String: String]? { nil }
  public var forceSendAsGetParams: Bool { false }
}
