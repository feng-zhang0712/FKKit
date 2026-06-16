import Foundation
import FKCoreKit

/// Shared fixtures and request models for FKNetworkClient tests.
enum NetworkTestFixtures {
  static let baseURL = URL(string: "https://mock.fkkit.test")!

  /// Builds an isolated network configuration for tests.
  static func makeConfiguration(
    enableMock: Bool = false,
    networkStatusProvider: (any NetworkStatusProviding)? = nil,
    callbackOnMainQueue: Bool = false,
    retryPolicy: FKNetworkRetryPolicy = .none
  ) -> FKNetworkConfiguration {
    let config = FKNetworkConfiguration(
      environment: .development,
      environmentMap: [.development: FKEnvironmentConfig(baseURL: baseURL)],
      enableMock: enableMock,
      callbackOnMainQueue: callbackOnMainQueue,
      retryPolicy: retryPolicy
    )
    config.networkStatusProvider = networkStatusProvider
    return config
  }

  /// Resolves the request URL for a path relative to ``baseURL``.
  static func url(forPath path: String) -> URL {
    let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    return baseURL.appendingPathComponent(trimmed)
  }

  /// Registers a canned JSON response on the mock session.
  static func stubJSON(
    session: FKMockNetworkSession,
    path: String,
    statusCode: Int = 200,
    json: String
  ) {
    let url = url(forPath: path)
    let data = Data(json.utf8)
    let response = HTTPURLResponse(
      url: url,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    )!
    session.stubbedResponses[url] = (data, response)
  }
}

/// Decodable user payload used by network integration tests.
struct StubUserDTO: Codable, Sendable, Equatable {
  let id: Int
  let name: String
}

/// Configurable GET request for stubbed user responses.
struct StubUserRequest: Requestable {
  typealias Response = StubUserDTO

  let path: String
  var mockData: Data?

  var method: HTTPMethod { .get }
}

/// Reachability stub for offline preflight tests.
struct StubNetworkStatus: NetworkStatusProviding, Sendable {
  let isReachable: Bool
}
