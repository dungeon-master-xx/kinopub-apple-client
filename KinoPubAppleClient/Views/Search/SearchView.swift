//
//  SearchView.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 24.06.2026.
//

import SwiftUI
import KinoPubUI
import KinoPubBackend

struct SearchView: View {
  @EnvironmentObject var navigationState: NavigationState
  @EnvironmentObject var authState: AuthState
  @EnvironmentObject var errorHandler: ErrorHandler
  @Environment(\.appContext) var appContext
  @StateObject private var model: SearchModel


  init(model: @autoclosure @escaping () -> SearchModel) {
    _model = StateObject(wrappedValue: model())
  }

  var body: some View {
    NavigationStack(path: $navigationState.searchRoutes) {
      WidthReader { width in
        ScrollView {
          if model.query.trimmingCharacters(in: .whitespaces).isEmpty {
            discoveryContent
          } else if model.allResults.isEmpty && !model.searching {
            EmptyStateView(systemImage: "magnifyingglass",
                           title: "Nothing found".localized,
                           message: "Try a different title, actor or director.".localized)
              .padding(.top, 80)
          } else {
            resultsContent(width: width)
          }
        }
      }
      .searchable(text: $model.query, placement: .automatic, prompt: "Shows & Movies")
      .kinoScreen("Search".localized)
      .routeDestinations()
      .handleError(state: $errorHandler.state)
    }
  }

  // MARK: - Discovery (empty query)

  @ViewBuilder
  var discoveryContent: some View {
    if !model.recentItems.isEmpty {
      VStack(alignment: .leading, spacing: 24) {
        recentSection
      }
      .padding(16)
    } else {
      EmptyStateView(systemImage: "magnifyingglass",
                     title: "Search".localized,
                     message: "Find movies, shows, actors and directors.".localized)
        .padding(.top, 80)
    }
  }

  var recentSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Recent")
          .font(Font.KinoPub.subheader)
          .foregroundStyle(Color.KinoPub.text)
        Spacer()
        Button("Clear") {
          model.clearRecents()
        }
        .foregroundStyle(Color.KinoPub.accent)
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(model.recentItems) { recent in
            NavigationLink(value: Route.details(MediaItem.mock(id: recent.id))) {
              recentCard(recent)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  private func recentCard(_ recent: RecentSearchItem) -> some View {
    HStack(spacing: 12) {
      CachedAsyncImage(url: URL(string: recent.poster)) { image in
        image.resizable().aspectRatio(contentMode: .fill)
      } placeholder: {
        Color.KinoPub.skeleton
      }
      .frame(width: 100, height: 62)
      .clipped()
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

      VStack(alignment: .leading, spacing: 2) {
        Text(recent.title)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(Color.KinoPub.text)
          .lineLimit(2)
        Text(recent.subtitle)
          .font(.system(size: 13))
          .foregroundStyle(Color.KinoPub.subtitle)
          .lineLimit(1)
      }
      .frame(width: 150, alignment: .leading)
    }
    .padding(8)
    .background(Color.white.opacity(0.06))
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  // MARK: - Results (non-empty query)

  func resultsContent(width: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      scopeTabBar
      LazyVGrid(columns: PosterGridLayout.columns(width: width), spacing: 16) {
        ForEach(model.results(for: model.scope), id: \.id) { item in
          if item.skeleton ?? false {
            PosterCard.placeholder(width: nil)
          } else {
            NavigationLink(value: Route.details(item)) {
              PosterCard(imageURL: item.posters.medium, title: item.localizedTitle, width: nil)
                .overlay(alignment: .topTrailing) { MediaCardStatusBadge(item: item) }
            }
#if os(macOS)
            .buttonStyle(.plain)
#endif
            .simultaneousGesture(TapGesture().onEnded {
              model.recordRecent(item)
            })
          }
        }
      }
    }
    .padding(16)
  }

  // MARK: - Scope tabs (All / Titles / Actors / Directors), like the kino.pub web search

  @ViewBuilder
  private var scopeTabBar: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(SearchScope.allCases) { scope in
          scopeTab(scope)
        }
      }
    }
  }

  private func scopeTab(_ scope: SearchScope) -> some View {
    let isSelected = model.scope == scope
    return Button {
      model.scope = scope
    } label: {
      // Count badges removed: the per-scope counts didn't render reliably, so the tab just shows
      // its label (matching the simpler kino.pub behaviour).
      Text(scope.title.localized)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(isSelected ? Color.white : Color.KinoPub.text)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(Capsule().fill(isSelected ? Color.KinoPub.accent : Color.white.opacity(0.1)))
    }
    .buttonStyle(.plain)
  }

}

struct SearchView_Previews: PreviewProvider {
  @StateObject static var navState = NavigationState()

  static var previews: some View {
    SearchView(model: SearchModel(itemsService: VideoContentServiceMock(),
                                  authState: AuthState(authService: AuthorizationServiceMock(), accessTokenService: AccessTokenServiceMock()),
                                  errorHandler: ErrorHandler()))
      .environmentObject(navState)
  }
}
