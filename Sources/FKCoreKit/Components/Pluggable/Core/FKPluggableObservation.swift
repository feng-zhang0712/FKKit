import Foundation

/// A lightweight cancellation handle returned by observable pluggable services.
///
/// Retain the token for the lifetime of the subscription; call ``cancel()`` or
/// deinitialize the token to unregister the observer.
public final class FKPluggableObservationToken: @unchecked Sendable {
  private let onCancel: @Sendable () -> Void
  private let lock = NSLock()
  private var isCancelled = false

  /// Creates a token that runs `onCancel` exactly once.
  ///
  /// - Parameter onCancel: Cleanup executed on ``cancel()`` or deinit.
  public init(onCancel: @escaping @Sendable () -> Void) {
    self.onCancel = onCancel
  }

  /// Unregisters the observer if not already cancelled.
  public func cancel() {
    lock.lock()
    defer { lock.unlock() }
    guard isCancelled == false else { return }
    isCancelled = true
    onCancel()
  }

  deinit {
    cancel()
  }
}
