import XCTest
@testable import KinoPubBackend

final class CommentsDecodingTests: XCTestCase {

  private func decode(_ json: String) throws -> CommentsData {
    try JSONDecoder().decode(CommentsData.self, from: Data(json.utf8))
  }

  /// The shape exactly as documented at kinoapi.com (video-comments).
  func testDecodesDocumentedShape() throws {
    let json = """
    {
      "status": 200,
      "item": { "id": 1235, "title": "Книга крови" },
      "comments": [
        {
          "id": 1, "depth": 0, "unread": false, "deleted": false,
          "message": "comment message", "created": 1234234234, "rating": "0",
          "user": { "id": 123, "name": "UserName", "avatar": "http://gravatar.com/avatar/x" }
        }
      ]
    }
    """
    let data = try decode(json)
    XCTAssertEqual(data.comments.count, 1)
    let c = try XCTUnwrap(data.comments.first)
    XCTAssertEqual(c.id, 1)
    XCTAssertEqual(c.message, "comment message")
    XCTAssertEqual(c.created, 1234234234)
    XCTAssertEqual(c.rating, "0")
    XCTAssertEqual(c.user.name, "UserName")
  }

  /// kino.pub flips numeric types between requests. A strict decoder would drop the whole thread;
  /// these must still decode (id as string, rating as number, created as string, missing avatar).
  func testDecodesMixedTypes() throws {
    let json = """
    {
      "comments": [
        {
          "id": "7", "message": "hi", "created": "1700000000", "rating": 8,
          "user": { "id": "42", "name": "Bob" }
        }
      ]
    }
    """
    let data = try decode(json)
    let c = try XCTUnwrap(data.comments.first)
    XCTAssertEqual(c.id, 7)
    XCTAssertEqual(c.created, 1700000000)
    XCTAssertEqual(c.rating, "8")
    XCTAssertEqual(c.user.id, 42)
    XCTAssertNil(c.user.avatar)
  }

  /// One malformed comment must not drop the others (lossy array decoding).
  func testLossyKeepsValidComments() throws {
    let json = """
    {
      "comments": [
        { "id": 1, "message": "ok", "created": 1, "user": { "id": 1, "name": "A" } },
        12345,
        { "id": 2, "message": "also ok", "created": 2, "user": { "id": 2, "name": "B" } }
      ]
    }
    """
    let data = try decode(json)
    XCTAssertEqual(data.comments.count, 2)
  }

  func testEmptyOrMissingComments() throws {
    XCTAssertEqual(try decode(#"{"status":200}"#).comments.count, 0)
    XCTAssertEqual(try decode(#"{"comments":[]}"#).comments.count, 0)
  }
}
