import Foundation

/// In-memory session mock for tests and Examples.
public final class FKMockUserSession: FKUserSessionProviding, FKUserSessionObserving, @unchecked Sendable {
  private let lock = NSLock()
  private var observers: [UUID: @Sendable (Bool) -> Void] = [:]

  /// Whether the mock user is signed in.
  public private(set) var isAuthenticated = false

  /// Mock user identifier.
  public private(set) var userID: String?

  /// Creates an unsigned-out session mock.
  public init() {}

  /// Signs in programmatically and notifies observers.
  public func signIn(userID: String) {
    lock.lock()
    isAuthenticated = true
    self.userID = userID
    let handlers = Array(observers.values)
    lock.unlock()
    handlers.forEach { $0(true) }
  }

  /// Clears session state and notifies observers.
  public func signOut() throws {
    lock.lock()
    isAuthenticated = false
    userID = nil
    let handlers = Array(observers.values)
    lock.unlock()
    handlers.forEach { $0(false) }
  }

  /// Observes authentication changes.
  @discardableResult
  public func observeAuthenticationChange(
    _ handler: @escaping @Sendable (Bool) -> Void
  ) -> FKPluggableObservationToken {
    let id = UUID()
    lock.lock()
    observers[id] = handler
    let authenticated = isAuthenticated
    lock.unlock()
    handler(authenticated)
    return FKPluggableObservationToken { [weak self] in
      self?.lock.lock()
      self?.observers.removeValue(forKey: id)
      self?.lock.unlock()
    }
  }
}
