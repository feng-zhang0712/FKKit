import Foundation

/// Stores system background URLSession completion handlers until delegate events finish.
final class FKBackgroundSessionCoordinator: @unchecked Sendable {
  static let shared = FKBackgroundSessionCoordinator()

  private let lock = NSLock()
  private var handlers: [String: @Sendable () -> Void] = [:]

  private init() {}

  /// Registers a completion handler for the given background session identifier.
  func register(_ handler: @escaping @Sendable () -> Void, forSessionWithIdentifier identifier: String) {
    lock.lock()
    defer { lock.unlock() }
    handlers[identifier] = handler
  }

  /// Invokes and removes a stored completion handler when background events finish.
  func invoke(forSessionWithIdentifier identifier: String) {
    lock.lock()
    let handler = handlers.removeValue(forKey: identifier)
    lock.unlock()
    handler?()
  }
}
