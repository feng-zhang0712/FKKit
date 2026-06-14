import Foundation

/// Keychain-backed credential store for Network and Pluggable auth flows.
public final class FKKeychainCredentialStore: TokenStore, FKCredentialProviding, @unchecked Sendable {
  private enum Key {
    static let accessToken = "fk.network.access_token"
    static let refreshToken = "fk.network.refresh_token"
  }

  private let storage: FKKeychainStorage

  /// Creates a credential store scoped to one Keychain service identifier.
  ///
  /// - Parameter service: Keychain service string (commonly bundle id + suffix).
  public init(service: String) {
    storage = FKKeychainStorage(service: service)
  }

  /// Current access token stored in Keychain.
  public var accessToken: String? {
    get { try? storage.value(key: Key.accessToken, as: String.self) }
    set {
      if let newValue {
        try? storage.set(newValue, key: Key.accessToken, ttl: nil)
      } else {
        try? storage.remove(key: Key.accessToken)
      }
    }
  }

  /// Current refresh token stored in Keychain.
  public var refreshToken: String? {
    get { try? storage.value(key: Key.refreshToken, as: String.self) }
    set {
      if let newValue {
        try? storage.set(newValue, key: Key.refreshToken, ttl: nil)
      } else {
        try? storage.remove(key: Key.refreshToken)
      }
    }
  }
}
