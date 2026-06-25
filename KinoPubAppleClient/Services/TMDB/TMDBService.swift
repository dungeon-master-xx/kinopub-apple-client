//
//  TMDBService.swift
//  KinoPubAppleClient
//
//  Resolves actor/director names to portrait photos via TMDB, since kino.pub returns
//  cast/director as plain text only. Results are cached in-memory per session.
//

import Foundation

/// Which TMDB department to prefer when several people share a name (an actor and a director can
/// have the same name — searching blindly returns the most popular, usually the actor).
enum TMDBPersonRole {
  case acting
  case directing

  var department: String {
    switch self {
    case .acting: return "Acting"
    case .directing: return "Directing"
    }
  }
}

/// A person matched on TMDB (used to show "which actors/directors matched" in search).
struct TMDBPerson: Identifiable, Hashable {
  let id: Int
  let name: String
  let imageURL: URL?
}

protocol TMDBService {
  func personImageURL(for name: String, role: TMDBPersonRole) async -> URL?
  /// People matching `query` whose known-for department is `role` (e.g. the actual actors/directors
  /// behind a name search), most-popular first.
  func people(matching query: String, role: TMDBPersonRole) async -> [TMDBPerson]
}

extension TMDBService {
  func personImageURL(for name: String) async -> URL? {
    await personImageURL(for: name, role: .acting)
  }
}

protocol TMDBServiceProvider {
  var tmdbService: TMDBService { get }
}

final class TMDBServiceImpl: TMDBService {

  private let apiKey: String
  private let session: URLSession
  private let cache = NSCache<NSString, NSURL>()
  private var misses = Set<String>()
  private let lock = NSLock()

  init(apiKey: String, session: URLSession = .shared) {
    self.apiKey = apiKey
    self.session = session
  }

  func personImageURL(for name: String, role: TMDBPersonRole) async -> URL? {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !apiKey.isEmpty else { return nil }
    // Cache per (role, name): the same name can resolve to different people as actor vs director.
    let key = "\(role.department):\(trimmed)"

    lock.lock()
    if let cached = cache.object(forKey: key as NSString) {
      lock.unlock()
      return cached as URL
    }
    if misses.contains(key) {
      lock.unlock()
      return nil
    }
    lock.unlock()

    guard var components = URLComponents(string: "https://api.themoviedb.org/3/search/person") else { return nil }
    components.queryItems = [
      URLQueryItem(name: "api_key", value: apiKey),
      URLQueryItem(name: "query", value: trimmed),
      URLQueryItem(name: "include_adult", value: "false")
    ]
    guard let url = components.url else { return nil }

    do {
      let (data, _) = try await session.data(from: url)
      let response = try JSONDecoder().decode(PersonSearchResponse.self, from: data)
      let withPhoto = response.results.filter { $0.profilePath != nil }
      // Prefer the person actually known for this role (the director, not the same-named actor),
      // falling back to the most popular match when none is tagged.
      let match = withPhoto.first(where: { $0.knownForDepartment == role.department }) ?? withPhoto.first
      if let path = match?.profilePath,
         let imageURL = URL(string: "https://image.tmdb.org/t/p/w185\(path)") {
        lock.lock()
        cache.setObject(imageURL as NSURL, forKey: key as NSString)
        lock.unlock()
        return imageURL
      }
    } catch {
      // Network/decoding failures fall through to "no photo".
    }

    lock.lock()
    misses.insert(key)
    lock.unlock()
    return nil
  }

  func people(matching query: String, role: TMDBPersonRole) async -> [TMDBPerson] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !apiKey.isEmpty else { return [] }

    guard var components = URLComponents(string: "https://api.themoviedb.org/3/search/person") else { return [] }
    components.queryItems = [
      URLQueryItem(name: "api_key", value: apiKey),
      URLQueryItem(name: "query", value: trimmed),
      URLQueryItem(name: "include_adult", value: "false")
    ]
    guard let url = components.url else { return [] }

    do {
      let (data, _) = try await session.data(from: url)
      let response = try JSONDecoder().decode(PersonSearchResponse.self, from: data)
      return response.results
        .filter { $0.knownForDepartment == role.department }
        .prefix(12)
        .map { person in
          let imageURL = person.profilePath.flatMap { URL(string: "https://image.tmdb.org/t/p/w185\($0)") }
          return TMDBPerson(id: person.id, name: person.name, imageURL: imageURL)
        }
    } catch {
      return []
    }
  }

  private struct PersonSearchResponse: Decodable {
    let results: [Person]
    struct Person: Decodable {
      let id: Int
      let name: String
      let profilePath: String?
      let knownForDepartment: String?
      enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case knownForDepartment = "known_for_department"
      }
    }
  }
}

struct TMDBServiceMock: TMDBService {
  func personImageURL(for name: String, role: TMDBPersonRole) async -> URL? { nil }
  func people(matching query: String, role: TMDBPersonRole) async -> [TMDBPerson] { [] }
}
