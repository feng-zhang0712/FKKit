import Foundation

/// Read/write credential storage used by auth interceptors and refresh flows.
///
/// Production implementations typically wrap Keychain or an encrypted store.
/// Tests can use in-memory conformers.
public protocol FKCredentialProviding: AnyObject, Sendable {
  /// Bearer access token for authenticated API calls.
  var accessToken: String? { get set }
  /// Refresh token used to obtain a new access token.
  var refreshToken: String? { get set }
}

/// Refreshes an expired access token when the backend returns `401`.
public protocol FKTokenRefreshing: Sendable {
  /// Requests a new access token.
  ///
  /// - Parameter refreshToken: Current refresh token from ``FKCredentialProviding``.
  /// - Returns: New access token string.
  /// - Throws: Refresh failures (revoked session, network error, etc.).
  func refreshAccessToken(using refreshToken: String?) async throws -> String
}

/// Reports whether the device currently has usable network connectivity.
public protocol FKNetworkReachabilityProviding: Sendable {
  /// `true` when outbound requests are expected to succeed.
  var isReachable: Bool { get }
}
