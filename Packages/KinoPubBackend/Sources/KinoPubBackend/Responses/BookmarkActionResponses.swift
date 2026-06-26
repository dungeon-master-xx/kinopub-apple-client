//
//  BookmarkActionResponses.swift
//

import Foundation

/// `POST /v1/bookmarks/create` → `{status, folder:{id,…}}`.
public struct CreateBookmarkFolderData: Codable {
  public struct Folder: Codable { public let id: Int }
  public let folder: Folder
}

/// `GET /v1/bookmarks/get-item-folders?item=` → `{status, folders:[{id,…}]}`.
public struct ItemFoldersData: Codable {
  public struct Folder: Codable { public let id: Int }
  public let folders: [Folder]
}
