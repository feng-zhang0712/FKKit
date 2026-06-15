import Foundation

/// Keychain-backed credential store for Network and Pluggable auth flows.
public final class FKKeychainCredentialStore: TokenStore, FKCredentialProviding, @unchecked Sendable {
  private let storage: FKKeychainStorage
  private let accessTokenKey: String
  private let refreshTokenKey: String

  /// Creates a credential store scoped to one Keychain service identifier.
  ///
  /// - Parameters:
  ///   - service: Keychain service string (commonly bundle id + suffix).
  ///   - accessTokenKey: Logical key for the access token (default `fk.network.access_token`).
  ///   - refreshTokenKey: Logical key for the refresh token (default `fk.network.refresh_token`).
  public init(
    service: String,
    accessTokenKey: String = "fk.network.access_token",
    refreshTokenKey: String = "fk.network.refresh_token"
  ) {
    storage = FKKeychainStorage(service: service)
    self.accessTokenKey = accessTokenKey
    self.refreshTokenKey = refreshTokenKey
  }

  /// Current access token stored in Keychain.
  public var accessToken: String? {
    get { try? storage.value(key: accessTokenKey, as: String.self) }
    set {
      if let newValue {
        try? storage.set(newValue, key: accessTokenKey, ttl: nil)
      } else {
        try? storage.remove(key: accessTokenKey)
      }
    }
  }

  /// Current refresh token stored in Keychain.
  public var refreshToken: String? {
    get { try? storage.value(key: refreshTokenKey, as: String.self) }
    set {
      if let newValue {
        try? storage.set(newValue, key: refreshTokenKey, ttl: nil)
      } else {
        try? storage.remove(key: refreshTokenKey)
      }
    }
  }
}
