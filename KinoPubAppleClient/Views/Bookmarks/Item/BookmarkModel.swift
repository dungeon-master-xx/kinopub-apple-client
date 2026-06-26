//
//  BookmarkModel.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 6.08.2023.
//

import Foundation
import KinoPubBackend
import KinoPubUI
import OSLog
import KinoPubLogging

/// Client-side sort options for a single bookmark folder. Mirrors the web "Сортировка".
enum BookmarkSort: CaseIterable, Identifiable {
  case added
  case title
  case year
  case imdb
  case kinopoisk

  var id: Self { self }

  var title: String {
    switch self {
    case .added: return "Added".localized
    case .title: return "Title".localized
    case .year: return "Year".localized
    case .imdb: return "IMDb".localized
    case .kinopoisk: return "Kinopoisk".localized
    }
  }
}

@MainActor
class BookmarkModel: ObservableObject {

  private var contentService: VideoContentService
  private var actionsService: UserActionsService
  private var errorHandler: ErrorHandler

  public var bookmark: Bookmark
  @Published public var items: [MediaItem] = MediaItem.skeletonMock()
  @Published public var toastMessage: ToastMessage?
  @Published public var sort: BookmarkSort = .added
  /// Latest folder title (kept in sync after a rename so the nav bar updates).
  @Published public var title: String

  init(bookmark: Bookmark,
       itemsService: VideoContentService,
       actionsService: UserActionsService,
       errorHandler: ErrorHandler) {
    self.contentService = itemsService
    self.actionsService = actionsService
    self.bookmark = bookmark
    self.title = bookmark.title
    self.errorHandler = errorHandler
  }

  /// Items rendered by the view, sorted client-side according to `sort`.
  /// `added` keeps the server order (default).
  var sortedItems: [MediaItem] {
    switch sort {
    case .added:
      return items
    case .title:
      return items.sorted { $0.localizedTitle.localizedCaseInsensitiveCompare($1.localizedTitle) == .orderedAscending }
    case .year:
      return items.sorted { $0.year > $1.year }
    case .imdb:
      return items.sorted { ($0.imdbRating ?? 0) > ($1.imdbRating ?? 0) }
    case .kinopoisk:
      return items.sorted { ($0.kinopoiskRating ?? 0) > ($1.kinopoiskRating ?? 0) }
    }
  }

  func fetchItems() async {
    do {
      items = try await contentService.fetchBookmarkItems(id: "\(bookmark.id)").items
    } catch {
      Logger.app.debug("fetch bookmark items error: \(error)")
      errorHandler.setError(error)
    }
  }

  @MainActor
  func refresh() {
    items = MediaItem.skeletonMock()
    Task {
      Logger.app.debug("refetch bookmark items")
      await fetchItems()
    }
  }

  /// Remove a single item from this folder (toggle-item against the folder). Optimistically drops
  /// it from the list and syncs the shared library state so other screens update too.
  func removeFromFolder(_ item: MediaItem) async {
    let previous = items
    items.removeAll { $0.id == item.id }  // optimistic
    AppContext.shared.libraryState.setBookmark(itemId: item.id, folderId: bookmark.id, isOn: false)
    do {
      try await actionsService.toggleBookmark(itemId: item.id, folderId: bookmark.id)
      toastMessage = .info(String(format: "Removed from %@".localized, bookmark.title))
    } catch {
      items = previous  // revert
      AppContext.shared.libraryState.setBookmark(itemId: item.id, folderId: bookmark.id, isOn: true)
      Logger.app.debug("remove from folder error: \(error)")
      errorHandler.setError(error)
    }
  }

  /// Delete the folder. Returns true on success so the view can dismiss back to the folders list.
  func delete() async -> Bool {
    do {
      try await actionsService.removeBookmarkFolder(id: bookmark.id)
      // Drop it from the shared cache so the Bookmarks list removes the folder immediately.
      AppContext.shared.libraryState.removeCachedBookmarkFolder(id: bookmark.id)
      return true
    } catch {
      Logger.app.debug("remove bookmark folder error: \(error)")
      errorHandler.setError(error)
      return false
    }
  }

}
