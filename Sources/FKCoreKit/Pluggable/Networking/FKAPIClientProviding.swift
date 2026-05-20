import Foundation

/// Executes HTTP API requests using the host app's networking stack.
///
/// Conform in production with URLSession, Alamofire, or an internal gateway client.
/// Conform in tests with stubs that return canned ``FKAPIResponse`` values.
public protocol FKAPIClientProviding: Sendable {
  /// Performs a request and returns raw response data.
  ///
  /// - Parameter request: Transport-neutral request descriptor.
  /// - Returns: Response payload and HTTP metadata.
  /// - Throws: Transport, TLS, or client configuration errors.
  func perform(_ request: FKAPIRequest) async throws -> FKAPIResponse
}
