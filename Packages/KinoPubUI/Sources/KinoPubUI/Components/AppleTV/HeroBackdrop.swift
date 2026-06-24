//
//  HeroBackdrop.swift
//
//
//  Apple TV-style cinematic hero header: full-bleed backdrop with a gradient
//  fade into the background and an overlay slot for title / metadata / actions.
//

import SwiftUI

public struct HeroBackdrop<Overlay: View>: View {

  private let imageURL: String?
  private let height: CGFloat
  private let overlay: Overlay

  public init(imageURL: String?,
              height: CGFloat = 460,
              @ViewBuilder overlay: () -> Overlay) {
    self.imageURL = imageURL
    self.height = height
    self.overlay = overlay()
  }

  public var body: some View {
    ZStack(alignment: .bottomLeading) {
      AsyncImage(url: URL(string: imageURL ?? "")) { image in
        image
          .resizable()
          .renderingMode(.original)
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Color.KinoPub.skeleton
      }
      .frame(height: height)
      .frame(maxWidth: .infinity)
      .clipped()

      // Fade the bottom of the artwork into the page background for a seamless transition.
      LinearGradient(
        colors: [
          Color.KinoPub.background.opacity(0.0),
          Color.KinoPub.background.opacity(0.55),
          Color.KinoPub.background
        ],
        startPoint: .center,
        endPoint: .bottom
      )
      .frame(height: height)
      .allowsHitTesting(false)

      overlay
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    .frame(height: height)
  }
}
