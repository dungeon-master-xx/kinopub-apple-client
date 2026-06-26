//
//  RemoveBookmarkFolderRequest.swift
//
//
//  Created by Claude Opus 4.8 on 25.06.2026.
//

import Foundation

/// Deletes a bookmark folder.
///
/// NOTE: best-effort endpoint. kino.pub's public docs don't fully spell out the folder-remove
/// route, so this mirrors `ToggleBookmarkFolderRequest`'s GET + `forceSendAsGetParams` style and
/// targets `/v1/bookmarks/{id}/remove`. Adjust the path if the API differs.
public struct RemoveBookmarkFolderRequest: Endpoint {

  public var id: Int

  public init(id: Int) {
    self.id = id
  }

  public var path: String {
    "/v1/bookmarks/\(id)/remove"
  }

  public var method: String {
    "POST"
  }

  public var parameters: [String: Any]? {
    nil
  }

  public var headers: [String: String]? {
    nil
  }

  public var forceSendAsGetParams: Bool { true }
}
