//
//  OfflineViews.swift
//  KinoPubUI
//
//  Offline-mode UI: a slim status banner and a "needs connection" placeholder. Strings are passed
//  in by the app (so this stays decoupled from app localization).
//

import SwiftUI

/// A slim, calm status bar shown at the top of the app while offline (or briefly when reconnected).
public struct OfflineBanner: View {

  public enum Tone {
    case warning
    case success

    var color: Color {
      switch self {
      case .warning: return Color.orange
      case .success: return Color.KinoPub.accent
      }
    }

    var icon: String {
      switch self {
      case .warning: return "wifi.slash"
      case .success: return "wifi"
      }
    }
  }

  private let tone: Tone
  private let title: String

  public init(tone: Tone, title: String) {
    self.tone = tone
    self.title = title
  }

  public var body: some View {
    HStack(spacing: 8) {
      Image(systemName: tone.icon)
      Text(title)
        .font(.system(size: 13, weight: .semibold))
      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 16)
    .padding(.vertical, 9)
    .frame(maxWidth: .infinity)
    .background(tone.color)
  }
}

/// Placeholder shown in a network-only section while offline, with a button to jump to Downloads.
public struct OfflineUnavailableView: View {

  private let title: String
  private let message: String
  private let actionTitle: String
  private let action: () -> Void

  public init(title: String, message: String, actionTitle: String, action: @escaping () -> Void) {
    self.title = title
    self.message = message
    self.actionTitle = actionTitle
    self.action = action
  }

  public var body: some View {
    VStack(spacing: 14) {
      Image(systemName: "wifi.slash")
        .font(.system(size: 44, weight: .light))
        .foregroundStyle(Color.KinoPub.subtitle)
      Text(title)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(Color.KinoPub.text)
        .multilineTextAlignment(.center)
      Text(message)
        .font(.system(size: 13))
        .foregroundStyle(Color.KinoPub.subtitle)
        .multilineTextAlignment(.center)
      Button(action: action) {
        Text(actionTitle)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 18)
          .padding(.vertical, 10)
          .background(Capsule().fill(Color.KinoPub.accent))
      }
      .buttonStyle(.plain)
      .padding(.top, 4)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(40)
    .background(Color.KinoPub.background)
  }
}
