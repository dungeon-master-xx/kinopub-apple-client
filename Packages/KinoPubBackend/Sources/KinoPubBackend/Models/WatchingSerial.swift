//
//  WatchingSerial.swift
//
//
//  Created by Kirill Kunst on 24.06.2026.
//

import Foundation

public struct WatchingSerial: Codable, Hashable, Identifiable {
  public let id: Int
  public let type: String
  public let subtype: String?
  public let title: String
  public let posters: Posters
  public let total: Int?
  public let watched: Int?
  public let new: Int?

  private enum CodingKeys: String, CodingKey {
    case id
    case type
    case subtype
    case title
    case posters
    case total
    case watched
    case new
  }

  public init(id: Int, type: String, subtype: String?, title: String, posters: Posters, total: Int?, watched: Int?, new: Int?) {
    self.id = id
    self.type = type
    self.subtype = subtype
    self.title = title
    self.posters = posters
    self.total = total
    self.watched = watched
    self.new = new
  }
}

public extension WatchingSerial {
  var localizedTitle: String {
    title.split(separator: "/").first?.trimmingCharacters(in: .whitespaces) ?? title
  }

  var originalTitle: String {
    title.split(separator: "/").last?.trimmingCharacters(in: .whitespaces) ?? title
  }

  static func mock(id: Int = 1, new: Int = 3) -> WatchingSerial {
    WatchingSerial(id: id,
                   type: "serial",
                   subtype: "",
                   title: "Рик и Морти / Rick and Morty",
                   posters: Posters(small: "", medium: "", big: "", wide: nil),
                   total: 71,
                   watched: 58,
                   new: new)
  }
}
