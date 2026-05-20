import Foundation

/// High-level application lifecycle states for pluggable observers.
///
/// Prefixed to avoid clashing with ``FKAppLifecycleState`` in BusinessKit.
public enum FKPluggableAppLifecycleState: String, Sendable, Hashable, CaseIterable {
  case active
  case inactive
  case background
  case terminated
}

/// Observes app lifecycle transitions without importing feature modules into UIKit hooks.
///
/// Production implementations usually forward `UIApplication` notifications.
public protocol FKAppLifecycleObserving: AnyObject, Sendable {
  /// Current lifecycle state.
  var state: FKPluggableAppLifecycleState { get }

  /// Registers a state-change handler.
  ///
  /// - Parameter handler: Called on every transition.
  /// - Returns: Cancellation token.
  @discardableResult
  func observe(
    _ handler: @escaping @Sendable (FKPluggableAppLifecycleState) -> Void
  ) -> FKPluggableObservationToken
}
