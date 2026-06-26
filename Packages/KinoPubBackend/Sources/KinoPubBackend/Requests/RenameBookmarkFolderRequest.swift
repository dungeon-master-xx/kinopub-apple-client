//
//  RenameBookmarkFolderRequest.swift
//
//
//  Created by Claude Opus 4.8 on 25.06.2026.
//

import Foundation

/// Renames a bookmark folder.
///
/// NOTE: best-effort endpoint. kino.pub's public docs don't fully spell out the folder-update
/// route, so this mirrors `ToggleBookmarkFolderRequest`'s GET + `forceSendAsGetParams` style and
/// targets `/v1/bookmarks/{id}/update?title=...`. Adjust the path if the API differs.
public struct RenameBookmarkFolderRequest: Endpoint {

  public var id: Int
  public var title: String

  public init(id: Int, title: String) {
    self.id = id
    self.title = title
  }

  public var path: String {
    "/v1/bookmarks/\(id)/update"
  }

  public var method: String {
    "POST"
  }

  public var parameters: [String: Any]? {
    ["title": title]
  }

  public var headers: [String: String]? {
    nil
  }

  public var forceSendAsGetParams: Bool { true }
}
