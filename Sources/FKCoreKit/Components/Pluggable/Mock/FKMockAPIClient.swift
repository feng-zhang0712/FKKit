import Foundation

/// Canned ``FKAPIClientProviding`` for tests and Examples.
public final class FKMockAPIClient: FKAPIClientProviding, @unchecked Sendable {
  private let lock = NSLock()
  private var responses: [String: Result<FKAPIResponse, Error>] = [:]
  private var defaultResponse: Result<FKAPIResponse, Error>?

  /// Creates a mock API client.
  public init() {}

  /// Registers a canned response for an exact URL string key.
  public func setResponse(_ result: Result<FKAPIResponse, Error>, forURL url: URL) {
    lock.lock()
    responses[url.absoluteString] = result
    lock.unlock()
  }

  /// Sets the fallback response when no URL-specific stub exists.
  public func setDefaultResponse(_ result: Result<FKAPIResponse, Error>) {
    lock.lock()
    defaultResponse = result
    lock.unlock()
  }

  /// Performs a stubbed API call.
  public func perform(_ request: FKAPIRequest) async throws -> FKAPIResponse {
    let keyed = resolvedResponse(for: request.url)
    switch keyed {
    case .success(let response):
      return response
    case .failure(let error):
      throw error
    case .none:
      return FKAPIResponse(data: Data(), httpResponse: nil)
    }
  }

  private func resolvedResponse(for url: URL) -> Result<FKAPIResponse, Error>? {
    lock.lock()
    defer { lock.unlock() }
    return responses[url.absoluteString] ?? defaultResponse
  }
}
