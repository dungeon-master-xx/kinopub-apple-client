//
//  UserActionsService.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 11.11.2023.
//

import Foundation
import KinoPubBackend

protocol UserActionsService {
  func markWatch(id: Int, time: Int, video: Int?, season: Int?) async throws
  func toggleWatching(id: Int, video: Int?, season: Int?) async throws
  func toggleWatchlist(id: Int) async throws
  func toggleBookmark(itemId: Int, folderId: Int) async throws
  func fetchBookmarks() async throws -> [Bookmark]
  func renameBookmarkFolder(id: Int, title: String) async throws
  func removeBookmarkFolder(id: Int) async throws
  func fetchWatchMark(id: Int, video: Int?, season: Int?) async throws -> WatchData
}

protocol UserActionsServiceProvider {
  var actionsService: UserActionsService { get set }
}

struct UserActionsServiceMock: UserActionsService {
  func markWatch(id: Int, time: Int, video: Int?, season: Int?) async throws {
    
  }
  
  func toggleWatching(id: Int, video: Int?, season: Int?) async throws {

  }

  func toggleWatchlist(id: Int) async throws {

  }

  func toggleBookmark(itemId: Int, folderId: Int) async throws {

  }

  func fetchBookmarks() async throws -> [Bookmark] {
    []
  }

  func renameBookmarkFolder(id: Int, title: String) async throws {

  }

  func removeBookmarkFolder(id: Int) async throws {

  }

  func fetchWatchMark(id: Int, video: Int?, season: Int?) async throws -> WatchData {
    WatchData.mock
  }
}
