//
//  PlayerView.swift
//  KinoPubAppleClient
//
//  Created by Kirill Kunst on 3.08.2023.
//

import Foundation
import SwiftUI
import AVKit

struct PlayerView: View {

  @StateObject private var playerManager: PlayerManager
  @State private var hideControls = false
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var navigationState: NavigationState

  init(manager: @autoclosure @escaping () -> PlayerManager) {
    _playerManager = StateObject(wrappedValue: manager())
  }

  var body: some View {
    GeometryReader { _ in
      ZStack(alignment: .topLeading) {
        videoPlayer
        closeButton
        if let continueTime = playerManager.continueTime {
          continueWatching(to: continueTime)
        }
      }
      .ignoresSafeArea(.all)
    }
    .ignoresSafeArea(.all)
#if os(macOS)
    .toolbar(.hidden, for: .windowToolbar)
    .onAppear(perform: {
      toggleSidebar()
    })
#endif
#if os(iOS)
    .navigationBarHidden(true)
    .toolbar(.hidden, for: .tabBar)
    .onChange(of: playerManager.isPlaying) { isPlaying in
      hideControls = isPlaying
    }
    .onAppear(perform: {
      UIApplication.shared.isIdleTimerDisabled = true
      configureAudioSession()
      UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
      AppDelegate.orientationLock = .landscape
      toggleSidebar()
      Task {
        await playerManager.fetchWatchMark()
      }
    })
    .onDisappear(perform: {
      UIApplication.shared.isIdleTimerDisabled = false
      AppDelegate.orientationLock = .all
      UIDevice.current.setValue(UIDevice.current.orientation.rawValue, forKey: "orientation")
      UIViewController.attemptRotationToDeviceOrientation()
    })
#endif
  }

  @ViewBuilder
  var videoPlayer: some View {
#if os(iOS)
    // AVPlayerViewController provides the native transport controls, AirPlay and the
    // Picture-in-Picture button (which SwiftUI's VideoPlayer does not expose).
    SystemVideoPlayer(player: playerManager.player)
      .onAppear { playerManager.player.play() }
#else
    VideoPlayer(player: playerManager.player)
      .onAppear { playerManager.player.play() }
#endif
  }

  // A native-style circular close control instead of a bare back chevron.
  var closeButton: some View {
    HStack(alignment: .top) {
      Button(action: { dismiss() }, label: {
        Image(systemName: "xmark")
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 36, height: 36)
          .background(.ultraThinMaterial, in: Circle())
      })
#if os(macOS)
      .buttonStyle(PlainButtonStyle())
#endif
      .padding(.leading, 20)
      .padding(.top, 16)
      .contentShape(Rectangle())
      .accessibilityLabel("Close")
      Spacer()
    }
    .fixedSize(horizontal: false, vertical: true)
    .opacity(hideControls ? 0.0 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: hideControls)
  }

#if os(iOS)
  private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .moviePlayback)
    try? session.setActive(true)
  }
#endif

  func continueWatching(to continueTime: TimeInterval) -> some View {
    VStack(alignment: .center) {
      Spacer()
      PlayerContinueWatchingView(time: continueTime, onContinueWatching: {
        playerManager.seekToContinueWatching()
      }, onCancelContinueWatching: {
        playerManager.cancelContinueWatching()
      })
      .frame(width: 180, height: 50)
      .padding(.bottom, 50)
    }
    .frame(maxWidth: .infinity)
  }

  private func toggleSidebar() {
    navigationState.columnVisibility = .detailOnly
  }
}

#if os(iOS)
/// Wraps `AVPlayerViewController` so we get the native playback chrome including
/// the Picture-in-Picture button.
private struct SystemVideoPlayer: UIViewControllerRepresentable {
  let player: AVPlayer

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller = AVPlayerViewController()
    controller.player = player
    controller.allowsPictureInPicturePlayback = true
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    controller.videoGravity = .resizeAspect
    controller.showsPlaybackControls = true
    return controller
  }

  func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
    if controller.player !== player {
      controller.player = player
    }
  }
}
#endif
