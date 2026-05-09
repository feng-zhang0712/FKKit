import Foundation
import FKCoreKit

// MARK: - Mock payloads

enum FKNetworkExampleMockPayloads {
  /// Wrapped envelope decoded after `FKNetworkExampleEnvelopeInterceptor`.
  static var envelopeUserJSON: Data {
    """
    {"data":{"id":42,"name":"Envelope Mock User","username":"envelope","email":"envelope@example.com"}}
    """.data(using: .utf8)!
  }

  /// Plain user JSON (no envelope); interceptor leaves body unchanged.
  static var plainUserJSON: Data {
    """
    {"id":99,"name":"Plain Mock User","username":"plain","email":"plain@example.com"}
    """.data(using: .utf8)!
  }
}

// MARK: - DTOs
//
// FKKitExamples sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which makes
// synthesized `Codable` conformances main-actor-isolated. `Requestable.Response`
// must be `Decodable & Sendable` for use from networking callbacks, so we use
// manual `nonisolated` decoding (and keep types `Sendable`).

/// Sample user payload from JSONPlaceholder `/users/:id`.
struct FKNetworkDemoUser: Sendable {
  let id: Int
  let name: String
  let username: String?
  let email: String?
}

extension FKNetworkDemoUser: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(Int.self, forKey: .id)
    name = try c.decode(String.self, forKey: .name)
    username = try c.decodeIfPresent(String.self, forKey: .username)
    email = try c.decodeIfPresent(String.self, forKey: .email)
  }

  private enum CodingKeys: String, CodingKey {
    case id, name, username, email
  }
}

/// Sample post payload from JSONPlaceholder `/posts`.
struct FKNetworkDemoPost: Sendable {
  let userId: Int
  let id: Int?
  let title: String
  let body: String
}

extension FKNetworkDemoPost: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    userId = try c.decode(Int.self, forKey: .userId)
    id = try c.decodeIfPresent(Int.self, forKey: .id)
    title = try c.decode(String.self, forKey: .title)
    body = try c.decode(String.self, forKey: .body)
  }

  private enum CodingKeys: String, CodingKey {
    case userId
    case id
    case title
    case body
  }
}

/// Decodes a top-level JSON array of posts (API returns `[{...}, ...]`).
struct FKNetworkDemoPostList: Sendable {
  let posts: [FKNetworkDemoPost]
}

extension FKNetworkDemoPostList: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    var items: [FKNetworkDemoPost] = []
    while !container.isAtEnd {
      items.append(try container.decode(FKNetworkDemoPost.self))
    }
    posts = items
  }
}

/// Empty JSON object `{}` (JSONPlaceholder `DELETE` responses).
struct FKNetworkEmptyKeyedResponse: Sendable {}

extension FKNetworkEmptyKeyedResponse: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    _ = try decoder.container(keyedBy: EmptyKey.self)
  }

  private enum EmptyKey: CodingKey {}
}

// MARK: - HTTPBin payloads

struct FKNetworkHttpBinBearerPayload: Sendable {
  let authenticated: Bool
  let token: String?
}

extension FKNetworkHttpBinBearerPayload: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    authenticated = try c.decode(Bool.self, forKey: .authenticated)
    token = try c.decodeIfPresent(String.self, forKey: .token)
  }

  private enum CodingKeys: String, CodingKey {
    case authenticated
    case token
  }
}

struct FKNetworkHttpBinDelayPayload: Sendable {
  let url: String?
}

extension FKNetworkHttpBinDelayPayload: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    url = try c.decodeIfPresent(String.self, forKey: .url)
  }

  private enum CodingKeys: String, CodingKey {
    case url
  }
}

struct FKNetworkHttpBinGETPayload: Sendable {
  let headers: [String: String]
}

extension FKNetworkHttpBinGETPayload: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    headers = try c.decode([String: String].self, forKey: .headers)
  }

  private enum CodingKeys: String, CodingKey {
    case headers
  }
}

struct FKNetworkHttpBinFormPayload: Sendable {
  let form: [String: String]?
}

extension FKNetworkHttpBinFormPayload: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    form = try c.decodeIfPresent([String: String].self, forKey: .form)
  }

  private enum CodingKeys: String, CodingKey {
    case form
  }
}

// MARK: - JSONPlaceholder requests

struct FKNetworkGETUserRequest: Requestable {
  typealias Response = FKNetworkDemoUser

  let userID: Int

  var path: String { "/users/\(userID)" }
  var method: HTTPMethod { .get }
}

struct FKNetworkPOSTJSONPostRequest: Requestable {
  typealias Response = FKNetworkDemoPost

  let title: String
  let body: String
  let userID: Int

  var path: String { "/posts" }
  var method: HTTPMethod { .post }
  var encoding: ParameterEncoding { .json }
  var bodyParameters: [String: Any] {
    ["title": title, "body": body, "userId": userID]
  }
}

struct FKNetworkCommonQueryPostsRequest: Requestable {
  typealias Response = FKNetworkDemoPostList

  var path: String { "/posts" }
  var method: HTTPMethod { .get }
  var queryItems: [String: String] { ["_limit": "5"] }
}

struct FKNetworkCustomHeaderPostsRequest: Requestable {
  typealias Response = FKNetworkDemoPostList

  var path: String { "/posts" }
  var method: HTTPMethod { .get }
  var queryItems: [String: String] { ["_limit": "3"] }
  var headers: [String: String] { ["X-Demo-Header": "FKNetworkExample"] }
}

struct FKNetworkPUTPostRequest: Requestable {
  typealias Response = FKNetworkDemoPost

  var path: String { "/posts/1" }
  var method: HTTPMethod { .put }
  var encoding: ParameterEncoding { .json }
  var bodyParameters: [String: Any] {
    [
      "id": 1,
      "title": "Updated via FKNetwork example (PUT)",
      "body": "Full replacement body for PUT demonstration.",
      "userId": 1,
    ]
  }
}

struct FKNetworkPATCHPostRequest: Requestable {
  typealias Response = FKNetworkDemoPost

  var path: String { "/posts/1" }
  var method: HTTPMethod { .patch }
  var encoding: ParameterEncoding { .json }
  var bodyParameters: [String: Any] { ["title": "Patched title (PATCH)"] }
}

struct FKNetworkDELETEPostRequest: Requestable {
  typealias Response = FKNetworkEmptyKeyedResponse

  var path: String { "/posts/1" }
  var method: HTTPMethod { .delete }
}

struct FKNetworkMemoryCachedUserRequest: Requestable {
  typealias Response = FKNetworkDemoUser

  let userID: Int

  var path: String { "/users/\(userID)" }
  var method: HTTPMethod { .get }
  var cachePolicy: NetworkCachePolicy { .memory(ttl: 60) }
}

struct FKNetworkDiskCachedUserRequest: Requestable {
  typealias Response = FKNetworkDemoUser

  let userID: Int

  var path: String { "/users/\(userID)" }
  var method: HTTPMethod { .get }
  var cachePolicy: NetworkCachePolicy { .disk(ttl: 60) }
}

struct FKNetworkMemoryAndDiskCachedUserRequest: Requestable {
  typealias Response = FKNetworkDemoUser

  let userID: Int

  var path: String { "/users/\(userID)" }
  var method: HTTPMethod { .get }
  var cachePolicy: NetworkCachePolicy { .memoryAndDisk(ttl: 120) }
}

struct FKNetworkDedupPostsRequest: Requestable {
  typealias Response = FKNetworkDemoPostList

  var path: String { "/posts" }
  var method: HTTPMethod { .get }
  var queryItems: [String: String] { ["_limit": "8"] }
  var behavior: NetworkRequestBehavior { .idempotentDeduplicated }
}

/// One-second delayed response so a second in-flight duplicate can be rejected while the first is active.
struct FKNetworkHttpBinDedupDelayRequest: Requestable {
  typealias Response = FKNetworkHttpBinDelayPayload

  var path: String { "/delay/1" }
  var method: HTTPMethod { .get }
  var behavior: NetworkRequestBehavior { .idempotentDeduplicated }
}

struct FKNetworkEnvelopeMockUserRequest: Requestable {
  typealias Response = FKNetworkDemoUser

  var path: String { "/users/42" }
  var method: HTTPMethod { .get }
  var mockData: Data? { FKNetworkExampleMockPayloads.envelopeUserJSON }
}

struct FKNetworkPlainMockUserRequest: Requestable {
  typealias Response = FKNetworkDemoUser

  var path: String { "/users/99" }
  var method: HTTPMethod { .get }
  var mockData: Data? { FKNetworkExampleMockPayloads.plainUserJSON }
}

// MARK: - HTTPBin requests (second client; jsonplaceholder.typicode.com base unused)

struct FKNetworkHttpBinBearerRequest: Requestable {
  typealias Response = FKNetworkHttpBinBearerPayload

  var path: String { "/bearer" }
  var method: HTTPMethod { .get }
}

struct FKNetworkHttpBinDelayGETRequest: Requestable {
  typealias Response = FKNetworkHttpBinDelayPayload

  /// Two-second delayed JSON — cancel mid-flight to exercise `Cancellable`.
  var path: String { "/delay/2" }
  var method: HTTPMethod { .get }
}

struct FKNetworkHttpBinSignedGETRequest: Requestable {
  typealias Response = FKNetworkHttpBinGETPayload

  var path: String { "/get" }
  var method: HTTPMethod { .get }
}

struct FKNetworkHttpBinFormPOSTRequest: Requestable {
  typealias Response = FKNetworkHttpBinFormPayload

  var path: String { "/post" }
  var method: HTTPMethod { .post }
  var encoding: ParameterEncoding { .formURLEncoded }
  var bodyParameters: [String: Any] {
    ["example_field": "example_value", "sdk": "FKKit"]
  }
}
