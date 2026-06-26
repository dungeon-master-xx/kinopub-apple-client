//
//  MetadataBadge.swift
//
//
//  Apple TV-style small bordered metadata badges (4K, 16+, CC, Dolby, ...).
//

import SwiftUI

public struct MetadataBadge: View {

  private let text: String
  private let filled: Bool

  public init(_ text: String, filled: Bool = false) {
    self.text = text
    self.filled = filled
  }

  public var body: some View {
    Text(text)
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(filled ? Color.KinoPub.background : Color.KinoPub.text)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .fill(filled ? Color.KinoPub.text.opacity(0.9) : Color.clear)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .strokeBorder(Color.KinoPub.subtitle.opacity(0.7), lineWidth: filled ? 0 : 1)
      )
  }
}

/// A wrapping row of metadata badges interleaved with plain text items (year, duration).
public struct MetadataRow: View {

  public struct Item: Identifiable {
    public let id = UUID()
    let text: String
    let isBadge: Bool
    public init(text: String, isBadge: Bool) {
      self.text = text
      self.isBadge = isBadge
    }
  }

  private let items: [Item]

  public init(items: [Item]) {
    self.items = items
  }

  public var body: some View {
    HStack(spacing: 8) {
      ForEach(items) { item in
        if item.isBadge {
          MetadataBadge(item.text)
        } else {
          Text(item.text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.KinoPub.subtitle)
        }
      }
    }
  }
}
