//
//  PosterCard.swift
//
//
//  Apple TV-style vertical poster card with optional Top-10 rank and caption.
//

import SwiftUI

public struct PosterCard: View {

  private let imageURL: String?
  private let title: String?
  private let subtitle: String?
  private let rank: Int?
  private let width: CGFloat
  private let cornerRadius: CGFloat
  private let showsAppleTVStyleRank: Bool

  public init(imageURL: String?,
              title: String? = nil,
              subtitle: String? = nil,
              rank: Int? = nil,
              width: CGFloat = 130,
              cornerRadius: CGFloat = 10) {
    self.imageURL = imageURL
    self.title = title
    self.subtitle = subtitle
    self.rank = rank
    self.width = width
    self.cornerRadius = cornerRadius
    self.showsAppleTVStyleRank = rank != nil
  }

  private var height: CGFloat { width * 1.5 }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      poster
      if title != nil || subtitle != nil {
        caption
      }
    }
    .frame(width: width)
  }

  private var poster: some View {
    ZStack(alignment: .topLeading) {
      AsyncImage(url: URL(string: imageURL ?? "")) { image in
        image
          .resizable()
          .renderingMode(.original)
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Color.KinoPub.skeleton
      }
      .frame(width: width, height: height)
      .clipped()
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
      )

      if let rank, showsAppleTVStyleRank {
        Text("\(rank)")
          .font(.system(size: 40, weight: .heavy, design: .rounded))
          .foregroundStyle(.white)
          .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
          .padding(.leading, 8)
          .padding(.top, 4)
      }
    }
  }

  private var caption: some View {
    VStack(alignment: .leading, spacing: 1) {
      if let title {
        Text(title)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color.KinoPub.text)
          .lineLimit(1)
      }
      if let subtitle {
        Text(subtitle)
          .font(.system(size: 13))
          .foregroundStyle(Color.KinoPub.subtitle)
          .lineLimit(1)
      }
    }
  }
}
