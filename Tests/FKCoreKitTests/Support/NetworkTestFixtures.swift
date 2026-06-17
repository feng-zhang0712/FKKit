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

/// Mock transport that returns a sequence of HTTP status codes for the same URL.
final class SequentialStatusNetworkSession: NetworkSession, @unchecked Sendable {
  private let inner = FKMockNetworkSession()
  private let lock = NSLock()
  private var attempt = 0
  private let statusCodes: [Int]
  private let successBody: Data

  init(statusCodes: [Int], successBody: Data) {
    self.statusCodes = statusCodes
    self.successBody = successBody
  }

  func dataTask(
    with request: URLRequest,
    completionHandler: @escaping DataTaskCompletion
  ) -> URLSessionDataTask {
    lock.lock()
    let index = min(attempt, max(statusCodes.count - 1, 0))
    attempt += 1
    lock.unlock()

    if let url = request.url {
      updateStub(for: url, attemptIndex: index)
    }
    return inner.dataTask(with: request, completionHandler: completionHandler)
  }

  func uploadTask(
    with request: URLRequest,
    fromFile fileURL: URL,
    completionHandler: @escaping DataTaskCompletion
  ) -> URLSessionUploadTask {
    inner.uploadTask(with: request, fromFile: fileURL, completionHandler: completionHandler)
  }

  func downloadTask(with request: URLRequest) -> URLSessionDownloadTask {
    inner.downloadTask(with: request)
  }

  func downloadTask(withResumeData resumeData: Data) -> URLSessionDownloadTask {
    inner.downloadTask(withResumeData: resumeData)
  }

  private func updateStub(for url: URL, attemptIndex: Int) {
    let statusCode = statusCodes[min(attemptIndex, statusCodes.count - 1)]
    let body = statusCode == 200 ? successBody : Data()
    let response = HTTPURLResponse(
      url: url,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    )!
    inner.stubbedResponses[url] = (body, response)
  }
}
