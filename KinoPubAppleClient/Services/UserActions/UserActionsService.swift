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
  func createBookmarkFolder(title: String) async throws -> Int
  func removeBookmarkFolder(id: Int) async throws
  func foldersContaining(itemId: Int) async throws -> [Int]
  func fetchWatchMark(id: Int, video: Int?, season: Int?) async throws -> WatchData
  /// Up-vote (like=1) or remove the vote (like=0) for an item.
  func vote(id: Int, like: Int) async throws -> VoteData
  // History management (kinoapi.com /v1/history/clear-for-*).
  func clearHistory(forMedia id: Int) async throws
  func clearHistory(forSeason id: Int) async throws
  func clearHistory(forItem id: Int) async throws
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

  func createBookmarkFolder(title: String) async throws -> Int {
    0
  }

  func removeBookmarkFolder(id: Int) async throws {

  }

  func foldersContaining(itemId: Int) async throws -> [Int] {
    []
  }

  func fetchWatchMark(id: Int, video: Int?, season: Int?) async throws -> WatchData {
    WatchData.mock
  }

  func vote(id: Int, like: Int) async throws -> VoteData {
    VoteData(voted: like == 1, total: nil, positive: nil, negative: nil, rating: nil)
  }

  func clearHistory(forMedia id: Int) async throws {}
  func clearHistory(forSeason id: Int) async throws {}
  func clearHistory(forItem id: Int) async throws {}
}
