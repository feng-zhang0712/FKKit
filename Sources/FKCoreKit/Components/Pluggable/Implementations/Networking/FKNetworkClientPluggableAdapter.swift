import Foundation

/// Bridges ``FKNetworkClient`` to ``FKAPIClientProviding``.
public struct FKNetworkClientPluggableAdapter: FKAPIClientProviding, Sendable {
  private let client: FKNetworkClient

  /// Creates an adapter around a network client instance.
  public init(client: FKNetworkClient) {
    self.client = client
  }

  /// Performs a transport-level API call and returns raw response bytes.
  public func perform(_ request: FKAPIRequest) async throws -> FKAPIResponse {
    try await client.performAPIRequest(request)
  }
}
