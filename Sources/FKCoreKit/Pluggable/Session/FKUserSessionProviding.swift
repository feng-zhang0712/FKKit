import Foundation

/// Authenticated user session boundary for feature modules.
///
/// Features depend on this protocol instead of a concrete login manager singleton.
public protocol FKUserSessionProviding: AnyObject, Sendable {
  /// Whether the user is signed in with a valid session.
  var isAuthenticated: Bool { get }

  /// Stable user identifier when authenticated.
  var userID: String? { get }

  /// Clears local session state (tokens, profile cache). Does not define UI navigation.
  func signOut() throws
}

/// Observes session changes (login, logout, account switch).
public protocol FKUserSessionObserving: AnyObject, Sendable {
  /// Adds a handler invoked when authentication state changes.
  ///
  /// - Parameter handler: Receives `true` when signed in.
  /// - Returns: Cancellation token.
  @discardableResult
  func observeAuthenticationChange(
    _ handler: @escaping @Sendable (Bool) -> Void
  ) -> FKPluggableObservationToken
}
