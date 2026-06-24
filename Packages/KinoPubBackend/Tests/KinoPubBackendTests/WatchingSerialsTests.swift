//
//  WatchingSerialsTests.swift
//
//
//  Created by Kirill Kunst on 24.06.2026.
//

import XCTest
@testable import KinoPubBackend

final class WatchingSerialsTests: XCTestCase {

  private let baseURL = URL(string: "https://api.service-kp.com")!

  func testRequestOmitsSubscribedWhenNil() throws {
    let request = try XCTUnwrap(RequestBuilder(baseURL: baseURL).build(with: WatchingSerialsRequest()))
    XCTAssertEqual(request.httpMethod, "GET")
    let url = try XCTUnwrap(request.url)
    XCTAssertTrue(url.absoluteString.contains("/v1/watching/serials"))
    XCTAssertFalse(url.absoluteString.contains("subscribed"))
  }

  func testRequestIncludesSubscribedWhenProvided() throws {
    let request = try XCTUnwrap(RequestBuilder(baseURL: baseURL).build(with: WatchingSerialsRequest(subscribed: 1)))
    let url = try XCTUnwrap(request.url)
    XCTAssertTrue(url.absoluteString.contains("subscribed=1"))
  }

  func testDecodingWatchingSerialsResponse() throws {
    let json = """
    {
      "status": 200,
      "items": [
        {
          "id": 42,
          "type": "serial",
          "subtype": "",
          "title": "Рик и Морти / Rick and Morty",
          "posters": { "small": "s.jpg", "medium": "m.jpg", "big": "b.jpg" },
          "total": 71,
          "watched": 58,
          "new": 13
        }
      ]
    }
    """.data(using: .utf8)!

    let data = try JSONDecoder().decode(ArrayData<WatchingSerial>.self, from: json)
    XCTAssertEqual(data.items.count, 1)
    let serial = try XCTUnwrap(data.items.first)
    XCTAssertEqual(serial.id, 42)
    XCTAssertEqual(serial.new, 13)
    XCTAssertEqual(serial.total, 71)
    XCTAssertEqual(serial.localizedTitle, "Рик и Морти")
    XCTAssertEqual(serial.originalTitle, "Rick and Morty")
    XCTAssertEqual(serial.posters.medium, "m.jpg")
    XCTAssertNil(serial.posters.wide)
  }
}
