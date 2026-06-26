//
//  ToastModifier.swift
//
//
//  A transient bottom toast that auto-dismisses, used for lightweight confirmations
//  (e.g. "added to bookmarks").
//

import SwiftUI

public extension View {
  /// Presents a transient toast anchored to the bottom. Bind to an optional message;
  /// set it to a non-nil string to show, and it clears itself after `duration`.
  func toast(message: Binding<String?>, duration: TimeInterval = 2.0) -> some View {
    modifier(ToastModifier(message: message, duration: duration))
  }
}

private struct ToastModifier: ViewModifier {
  @Binding var message: String?
  let duration: TimeInterval

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .bottom) {
        if let message {
          ToastContentView(text: message)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: message) {
              try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
              withAnimation { self.message = nil }
            }
        }
      }
      .animation(.easeInOut(duration: 0.25), value: message)
  }
}
