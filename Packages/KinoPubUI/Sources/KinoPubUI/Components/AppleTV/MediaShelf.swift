//
//  MediaShelf.swift
//
//
//  Apple TV-style titled horizontal carousel ("shelf").
//

import SwiftUI

/// A titled horizontal carousel that mimics the Apple TV app "shelf" rows.
/// Compose the row contents (poster cards, episode cards, etc.) via the trailing closure.
public struct MediaShelf<Content: View>: View {

  private let title: String
  private let showsChevron: Bool
  private let spacing: CGFloat
  private let horizontalPadding: CGFloat
  private let onHeaderTap: (() -> Void)?
  private let content: Content

  public init(title: String,
              showsChevron: Bool = true,
              spacing: CGFloat = 14,
              horizontalPadding: CGFloat = 20,
              onHeaderTap: (() -> Void)? = nil,
              @ViewBuilder content: () -> Content) {
    self.title = title
    self.showsChevron = showsChevron
    self.spacing = spacing
    self.horizontalPadding = horizontalPadding
    self.onHeaderTap = onHeaderTap
    self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      header
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: spacing) {
          content
        }
        .padding(.horizontal, horizontalPadding)
      }
    }
  }

  private var header: some View {
    Button(action: { onHeaderTap?() }) {
      HStack(spacing: 6) {
        Text(title)
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(Color.KinoPub.text)
        if showsChevron && onHeaderTap != nil {
          Image(systemName: "chevron.right")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Color.KinoPub.subtitle)
        }
        Spacer(minLength: 0)
      }
      .contentShape(Rectangle())
      .padding(.horizontal, horizontalPadding)
    }
    .buttonStyle(.plain)
    .disabled(onHeaderTap == nil)
  }
}
