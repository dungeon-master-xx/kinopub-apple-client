//
//  BookmarkView.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 6.08.2023.
//

import Foundation
import SwiftUI
import KinoPubUI
import KinoPubBackend

struct BookmarkView: View {
  @EnvironmentObject var navigationState: NavigationState
  @EnvironmentObject var errorHandler: ErrorHandler

  @StateObject private var model: BookmarkModel
  @Environment(\.appContext) var appContext
  @Environment(\.dismiss) private var dismiss

  @State private var showDeleteConfirm = false

  init(model: @autoclosure @escaping () -> BookmarkModel) {
    _model = StateObject(wrappedValue: model())
  }

  var body: some View {
    VStack {
      if model.items.isEmpty {
        EmptyStateView(systemImage: "bookmark",
                       title: "This folder is empty".localized)
      } else {
        listView
      }
    }
    .navigationTitle(model.title)
    .background(Color.KinoPub.background)
    .toolbar {
#if os(iOS)
      ToolbarItem(placement: .topBarTrailing) {
        sortMenu
      }
      ToolbarItem(placement: .topBarTrailing) {
        deleteButton
      }
#else
      ToolbarItem(placement: .primaryAction) {
        sortMenu
      }
      ToolbarItem(placement: .primaryAction) {
        deleteButton
      }
#endif
    }
    .alert("Delete folder".localized, isPresented: $showDeleteConfirm) {
      Button("Cancel".localized, role: .cancel) {}
      Button("Delete".localized, role: .destructive) {
        Task {
          if await model.delete() {
            dismiss()
          }
        }
      }
    } message: {
      Text("This will permanently delete the folder.".localized)
    }
    .task {
      await model.fetchItems()
    }
    .handleError(state: $errorHandler.state)
    .toast(message: $model.toastMessage)
  }

  var sortMenu: some View {
    Menu {
      Picker("Sort".localized, selection: $model.sort) {
        ForEach(BookmarkSort.allCases) { option in
          Text(option.title).tag(option)
        }
      }
    } label: {
      Image(systemName: "arrow.up.arrow.down")
    }
  }

  // Folder delete is the only management action kino.pub's API supports (no rename endpoint exists).
  var deleteButton: some View {
    Button(role: .destructive) {
      showDeleteConfirm = true
    } label: {
      Image(systemName: "trash")
    }
  }

  var listView: some View {
    GeometryReader { geometryProxy in
      ContentItemsListView(width: geometryProxy.size.width, items: .constant(model.sortedItems), onLoadMoreContent: { item in

      }, onRefresh: {
        await model.refresh()
      }, navigationLinkProvider: { item in
        RouteLinkProvider().link(for: item)
      }, statusOverlay: { AnyView(MediaCardStatusBadge(item: $0)) },
         contextMenu: { item in
        AnyView(
          Button(role: .destructive) {
            Task { await model.removeFromFolder(item) }
          } label: {
            Label("Remove from folder".localized, systemImage: "bookmark.slash")
          }
        )
      })
    }
  }
}
