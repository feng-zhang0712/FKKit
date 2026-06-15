import Foundation

private enum FKUserSessionStorageKey {
  static let userID = "session.user_id"
}

/// Reference ``FKUserSessionProviding`` + ``FKUserSessionObserving`` backed by ``FKCodableStoring``.
public final class FKUserSessionStore: FKUserSessionProviding, FKUserSessionObserving, @unchecked Sendable {
  private let storage: any FKCodableStoring
  private let lock = NSLock()
  private var observers: [UUID: @Sendable (Bool) -> Void] = [:]
  private var cachedUserID: String?

  /// Creates a session store with optional persistence.
  ///
  /// - Parameter storage: Key-value storage for `userID`; use ``FKInMemoryKeyValueStore`` in tests.
  public init(storage: any FKCodableStoring) {
    self.storage = storage
    cachedUserID = try? storage.value(forKey: FKUserSessionStorageKey.userID, as: String.self)
  }

  /// Whether a user identifier is currently stored.
  public var isAuthenticated: Bool {
    lock.lock()
    defer { lock.unlock() }
    return cachedUserID?.isEmpty == false
  }

  /// Stable user identifier when authenticated.
  public var userID: String? {
    lock.lock()
    defer { lock.unlock() }
    return cachedUserID
  }

  /// Clears persisted session state and notifies observers with `false`.
  public func signOut() throws {
    do {
      try storage.remove(forKey: FKUserSessionStorageKey.userID)
    } catch {
      throw FKPluggableSessionError.storageFailure(underlying: error)
    }
    lock.lock()
    cachedUserID = nil
    let handlers = Array(observers.values)
    lock.unlock()
    handlers.forEach { $0(false) }
  }

  /// Observes authentication transitions; emits the current state immediately.
  @discardableResult
  public func observeAuthenticationChange(
    _ handler: @escaping @Sendable (Bool) -> Void
  ) -> FKPluggableObservationToken {
    let id = UUID()
    lock.lock()
    observers[id] = handler
    let authenticated = cachedUserID?.isEmpty == false
    lock.unlock()
    handler(authenticated)
    return FKPluggableObservationToken { [weak self] in
      self?.lock.lock()
      self?.observers.removeValue(forKey: id)
      self?.lock.unlock()
    }
  }

  /// Signs in by persisting `userID` (reference-implementation helper, not part of the protocol).
  public func signIn(userID: String) throws {
    guard userID.isEmpty == false else {
      throw FKPluggableSessionError.notAuthenticated
    }
    do {
      try storage.set(userID, forKey: FKUserSessionStorageKey.userID)
    } catch {
      throw FKPluggableSessionError.storageFailure(underlying: error)
    }
    lock.lock()
    cachedUserID = userID
    let handlers = Array(observers.values)
    lock.unlock()
    handlers.forEach { $0(true) }
  }
}
