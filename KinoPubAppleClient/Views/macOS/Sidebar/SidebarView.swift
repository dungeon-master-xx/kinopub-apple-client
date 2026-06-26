//
//  SidebarView.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 11.08.2023.
//

import Foundation
import SwiftUI
import KinoPubUI
import KinoPubBackend

struct SidebarView: View {

  @Environment(\.appContext) var appContext
  @EnvironmentObject var navigationState: NavigationState
  @EnvironmentObject var errorHandler: ErrorHandler
  @EnvironmentObject var authState: AuthState

  var body: some View {
    // Every section's detail NavigationStack now uses the shared `Route` element type, so the
    // NavigationSplitView detail column reconciles cleanly across section switches (no
    // AnyNavigationPath.comparisonTypeMismatch). That means no per-selection `.id` hack — the
    // sidebar keeps its identity, scroll position, and selection animation.
    NavigationSplitView(columnVisibility: $navigationState.columnVisibility) {
      Sidebar(selection: $navigationState.sidebarSelection)
    } detail: {
      SidebarNavigationDetail(selection: $navigationState.sidebarSelection)
    }
    .accentColor(Color.KinoPub.accent)
    .sheet(isPresented: $authState.shouldShowAuthentication, content: {
      authSheet
    })
    .environmentObject(navigationState)
    .environmentObject(errorHandler)
    .task {
      await authState.check()
    }
  }

  var authSheet: some View {
    AuthView(model: AuthModel(authService: appContext.authService,
                              authState: authState,
                              errorHandler: errorHandler))
#if os(macOS)
    .frame(width: 600, height: 600)
#endif
  }

}

struct SideBarView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarView()
  }
}
