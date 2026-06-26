//
//  Comment.swift
//
//
//  Comment on a film/episode. Matches GET /v1/items/comments (kinoapi.com → video-comments).
//
//  Decoding is deliberately tolerant: kino.pub is inconsistent about numeric types (it returns the
//  same field as a number in one response and a quoted string in another — see `Bookmark.count`).
//  A strict decoder would throw on that and, because the list is decoded lossily, drop *every*
//  comment and show an empty thread. So numeric fields accept either form and optional fields never
//  throw.
//

import Foundation

public struct Comment: Codable, Identifiable {
  public let id: Int
  public let message: String
  public let created: Int
  public let rating: String?
  public let depth: Int?
  public let unread: Bool?
  public let deleted: Bool?
  public let user: CommentUser

  public init(id: Int,
              message: String,
              created: Int,
              rating: String? = nil,
              depth: Int? = nil,
              unread: Bool? = nil,
              deleted: Bool? = nil,
              user: CommentUser) {
    self.id = id
    self.message = message
    self.created = created
    self.rating = rating
    self.depth = depth
    self.unread = unread
    self.deleted = deleted
    self.user = user
  }

  private enum CodingKeys: String, CodingKey {
    case id, message, created, rating, depth, unread, deleted, user
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = c.flexibleInt(forKey: .id) ?? 0
    message = (try? c.decode(String.self, forKey: .message)) ?? ""
    created = c.flexibleInt(forKey: .created) ?? 0
    rating = c.flexibleString(forKey: .rating)
    depth = c.flexibleInt(forKey: .depth)
    unread = try? c.decodeIfPresent(Bool.self, forKey: .unread)
    deleted = try? c.decodeIfPresent(Bool.self, forKey: .deleted)
    user = (try? c.decode(CommentUser.self, forKey: .user)) ?? CommentUser(id: 0, name: "")
  }
}

public struct CommentUser: Codable {
  public let id: Int
  public let name: String
  public let avatar: String?

  public init(id: Int, name: String, avatar: String? = nil) {
    self.id = id
    self.name = name
    self.avatar = avatar
  }

  private enum CodingKeys: String, CodingKey {
    case id, name, avatar
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = c.flexibleInt(forKey: .id) ?? 0
    name = (try? c.decode(String.self, forKey: .name)) ?? ""
    avatar = try? c.decodeIfPresent(String.self, forKey: .avatar)
  }
}

// MARK: - Tolerant decoding helpers

extension KeyedDecodingContainer {
  /// Decodes an Int that the API may send as a number or a numeric string. Returns nil if absent or
  /// not parseable.
  func flexibleInt(forKey key: Key) -> Int? {
    if let value = try? decodeIfPresent(Int.self, forKey: key) { return value }
    if let string = try? decodeIfPresent(String.self, forKey: key) { return Int(string) }
    if let double = try? decodeIfPresent(Double.self, forKey: key) { return Int(double) }
    return nil
  }

  /// Decodes a value that the API may send as a string or a number, normalised to a String. Returns
  /// nil if absent.
  func flexibleString(forKey key: Key) -> String? {
    if let string = try? decodeIfPresent(String.self, forKey: key) { return string }
    if let int = try? decodeIfPresent(Int.self, forKey: key) { return String(int) }
    if let double = try? decodeIfPresent(Double.self, forKey: key) { return String(double) }
    return nil
  }
}
