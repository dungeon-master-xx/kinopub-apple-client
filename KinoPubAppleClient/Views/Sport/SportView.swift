//
//  SportView.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 24.06.2026.
//

import SwiftUI
import KinoPubUI
import KinoPubBackend

struct SportView: View {
  @EnvironmentObject var navigationState: NavigationState
  @EnvironmentObject var authState: AuthState
  @EnvironmentObject var errorHandler: ErrorHandler
  @Environment(\.appContext) var appContext
  @StateObject private var model: SportModel

  // ~3 wide columns on iPad, fewer on iPhone.
  private let columns = [GridItem(.adaptive(minimum: 280), spacing: 16, alignment: .top)]

  init(model: @autoclosure @escaping () -> SportModel) {
    _model = StateObject(wrappedValue: model())
  }

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Sport")
        .background(Color.KinoPub.background)
        .task { await model.fetchChannels() }
        .refreshable { await model.refresh() }
        .navigationDestination(for: TVChannel.self) { channel in
          PlayerView(manager: PlayerManager(playItem: channel,
                                            watchMode: .media,
                                            downloadedFilesDatabase: appContext.downloadedFilesDatabase,
                                            actionsService: appContext.actionsService))
        }
        .handleError(state: $errorHandler.state)
    }
  }

  @ViewBuilder
  private var content: some View {
    if model.isLoading {
      VStack {
        Spacer()
        ProgressView().tint(Color.KinoPub.accent)
        Spacer()
      }
      .frame(maxWidth: .infinity)
    } else if model.channels.isEmpty {
      emptyState
    } else {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
          ForEach(model.channels) { channel in
            NavigationLink(value: channel) {
              LiveChannelCard(channel: channel)
            }
            #if os(macOS)
            .buttonStyle(.plain)
            #endif
          }
        }
        .padding(20)
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 10) {
      Spacer()
      Image(systemName: "sportscourt")
        .font(.system(size: 44))
        .foregroundStyle(Color.KinoPub.subtitle)
      Text("No live broadcasts right now")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(Color.KinoPub.subtitle)
        .multilineTextAlignment(.center)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// Apple TV-style live channel card: artwork/logo, a red LIVE badge, channel title.
struct LiveChannelCard: View {
  let channel: TVChannel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ZStack(alignment: .topLeading) {
        artwork
        liveBadge
          .padding(8)
      }
      Text(channel.title)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(Color.KinoPub.text)
        .lineLimit(1)
    }
  }

  private var artwork: some View {
    ZStack {
      Color.black
      CachedAsyncImage(url: URL(string: channel.logo ?? "")) { image in
        image
          .resizable()
          .renderingMode(.original)
          .aspectRatio(contentMode: .fit)
          .padding(24)
      } placeholder: {
        Image(systemName: "sportscourt.fill")
          .font(.system(size: 40))
          .foregroundStyle(Color.KinoPub.subtitle)
      }
    }
    .frame(maxWidth: .infinity)
    .aspectRatio(16.0 / 9.0, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
    )
  }

  private var liveBadge: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(Color.white)
        .frame(width: 6, height: 6)
      Text("LIVE")
        .font(.system(size: 11, weight: .heavy))
        .foregroundStyle(.white)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.red, in: Capsule())
  }
}

struct SportView_Previews: PreviewProvider {
  static var previews: some View {
    SportView(model: SportModel(itemsService: VideoContentServiceMock(),
                                authState: AuthState(authService: AuthorizationServiceMock(), accessTokenService: AccessTokenServiceMock()),
                                errorHandler: ErrorHandler()))
  }
}
