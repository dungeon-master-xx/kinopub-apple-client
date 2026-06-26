//
//  Subtitle.swift
//
//
//  Created by Kirill Kunst on 21.07.2023.
//

import Foundation

public struct Subtitle: Codable, Hashable {
  public let lang: String
  public let shift: Int
  public let embed: Bool
  public let url: String
  /// Whether this is a "forced" subtitle track (only foreign-language lines). Present in the live
  /// response but previously dropped. Optional so older/short responses still decode.
  public let forced: Bool?
  /// Server-side file path (alongside the playable `url`).
  public let file: String?
}
