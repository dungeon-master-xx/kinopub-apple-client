//
//  ContentItemRatingView.swift
//
//
//  Created by Kirill Kunst on 24.07.2023.
//

import Foundation
import SwiftUI
import SkeletonUI
/// Shared brand colours for the IMDb / Kinopoisk badges.
public enum RatingBrand {
  public static let imdbGold = Color(red: 0.96, green: 0.77, blue: 0.09)   // #F5C518
  public static let kinopoiskOrange = Color(red: 1.0, green: 0.40, blue: 0.0) // #FF6600
}

/// A small coloured "IMDb" / "КП" chip, reused by the tiles, the detail hero and the info block.
public struct RatingBadge: View {
  private let text: String
  private let background: Color
  private let foreground: Color

  public init(text: String, background: Color, foreground: Color) {
    self.text = text
    self.background = background
    self.foreground = foreground
  }

  public static var imdb: RatingBadge { RatingBadge(text: "IMDb", background: RatingBrand.imdbGold, foreground: .black) }
  public static var kinopoisk: RatingBadge { RatingBadge(text: "КП", background: RatingBrand.kinopoiskOrange, foreground: .white) }

  public var body: some View {
    Text(text)
      .font(.system(size: 10, weight: .heavy))
      .foregroundStyle(foreground)
      .padding(.horizontal, 4)
      .padding(.vertical, 2)
      .background(RoundedRectangle(cornerRadius: 3, style: .continuous).fill(background))
  }
}

/// "[КП] 8.5 / 334,457   [IMDb] 8.1 / 675,834" — the detailed ratings line for the info block.
public struct RatingsDetailRow: View {
  private let imdbScore: Double?
  private let imdbVotes: Int?
  private let kinopoiskScore: Double?
  private let kinopoiskVotes: Int?

  public init(imdbScore: Double?, imdbVotes: Int?, kinopoiskScore: Double?, kinopoiskVotes: Int?) {
    self.imdbScore = imdbScore
    self.imdbVotes = imdbVotes
    self.kinopoiskScore = kinopoiskScore
    self.kinopoiskVotes = kinopoiskVotes
  }

  public var body: some View {
    HStack(spacing: 18) {
      if (kinopoiskScore ?? 0) > 0 {
        item(RatingBadge.kinopoisk, score: kinopoiskScore!, votes: kinopoiskVotes)
      }
      if (imdbScore ?? 0) > 0 {
        item(RatingBadge.imdb, score: imdbScore!, votes: imdbVotes)
      }
    }
  }

  private func item(_ badge: RatingBadge, score: Double, votes: Int?) -> some View {
    HStack(spacing: 6) {
      badge
      Text(RatingsDetailRow.text(score: score, votes: votes))
        .font(.system(size: 14))
        .foregroundStyle(Color.KinoPub.text)
    }
  }

  private static func text(score: Double, votes: Int?) -> String {
    let scoreString = score.scoreFormatted
    guard let votes, votes > 0 else { return scoreString }
    let votesString = NumberFormatter.localizedString(from: NSNumber(value: votes), number: .decimal)
    return "\(scoreString) / \(votesString)"
  }
}

public struct ContentItemRatingView: View {

  var imdbScore: Double?
  var kinopoiskScore: Double?

  public init(imdbScore: Double?, kinopoiskScore: Double?) {
    self.imdbScore = imdbScore
    self.kinopoiskScore = kinopoiskScore
  }

  // Brand colours.
  private static let imdbGold = RatingBrand.imdbGold
  private static let kinopoiskOrange = RatingBrand.kinopoiskOrange

  @ViewBuilder
  public var body: some View {
    if isEmpty {
      // No real ratings — don't show the banner at all.
      EmptyView()
    } else {
      HStack(spacing: 5) {
        if hasImdb {
          badge("IMDb", background: Self.imdbGold, foreground: .black)
          score(imdbScore)
        }
        if hasKinopoisk {
          badge("КП", background: Self.kinopoiskOrange, foreground: .white)
          score(kinopoiskScore)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .background(Color.KinoPub.selectionBackground)
      .cornerRadius(8)
    }
  }

  // A score of nil or 0 means "no rating" — hide that source.
  private var hasImdb: Bool { (imdbScore ?? 0) > 0 }
  private var hasKinopoisk: Bool { (kinopoiskScore ?? 0) > 0 }

  var isEmpty: Bool {
    !hasImdb && !hasKinopoisk
  }

  private func badge(_ text: String, background: Color, foreground: Color) -> some View {
    Text(text)
      .font(.system(size: 10, weight: .heavy))
      .foregroundStyle(foreground)
      .padding(.horizontal, 4)
      .padding(.vertical, 2)
      .background(RoundedRectangle(cornerRadius: 3, style: .continuous).fill(background))
  }

  private func score(_ value: Double?) -> some View {
    Text(value?.scoreFormatted ?? "0.0")
      .font(.system(size: 13, weight: .semibold))
      .foregroundColor(.white)
  }

}

#Preview {
  ContentItemRatingView(imdbScore: 5.0, kinopoiskScore: 5.0)
}
