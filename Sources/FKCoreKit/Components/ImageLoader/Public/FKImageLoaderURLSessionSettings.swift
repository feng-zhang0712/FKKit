import Foundation

/// Equatable subset of `URLSessionConfiguration` used to rebuild sessions on config changes.
public struct FKImageLoaderURLSessionSettings: Sendable, Equatable {
  /// Per-request timeout (seconds).
  public var timeoutIntervalForRequest: TimeInterval
  /// Whether the session waits for connectivity before failing.
  public var waitsForConnectivity: Bool
  /// Maximum concurrent connections per host.
  public var httpMaximumConnectionsPerHost: Int

  /// Default session settings aligned with ``FKImageLoaderConfiguration`` defaults.
  public init(
    timeoutIntervalForRequest: TimeInterval = 60,
    waitsForConnectivity: Bool = true,
    httpMaximumConnectionsPerHost: Int = 6
  ) {
    self.timeoutIntervalForRequest = timeoutIntervalForRequest
    self.waitsForConnectivity = waitsForConnectivity
    self.httpMaximumConnectionsPerHost = max(1, httpMaximumConnectionsPerHost)
  }

  /// Builds a `URLSessionConfiguration` from these settings.
  public func makeConfiguration() -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
    configuration.waitsForConnectivity = waitsForConnectivity
    configuration.httpMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
    return configuration
  }
}
