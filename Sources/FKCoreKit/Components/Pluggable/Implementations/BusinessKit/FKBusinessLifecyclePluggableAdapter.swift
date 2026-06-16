import Foundation

/// Bridges ``FKBusinessLifecycleObserving`` to Pluggable ``FKAppLifecycleObserving``.
public final class FKBusinessLifecyclePluggableAdapter: FKAppLifecycleObserving, @unchecked Sendable {
  /// Underlying BusinessKit lifecycle observer.
  private let observer: FKBusinessLifecycleObserving

  /// Creates an adapter over a BusinessKit lifecycle observer.
  ///
  /// - Parameter observer: BusinessKit lifecycle implementation (default shared observer).
  public init(observer: FKBusinessLifecycleObserving = FKBusinessKit.shared.lifecycle) {
    self.observer = observer
  }

  /// Current lifecycle state mapped to Pluggable semantics.
  public var state: FKPluggableAppLifecycleState {
    Self.map(observer.state)
  }

  /// Registers a Pluggable lifecycle handler; emits the current mapped state immediately.
  @discardableResult
  public func observe(
    _ handler: @escaping @Sendable (FKPluggableAppLifecycleState) -> Void
  ) -> FKPluggableObservationToken {
    let token = observer.observe { businessState in
      handler(Self.map(businessState))
    }
    return FKPluggableObservationToken {
      token.invalidate()
    }
  }

  /// Maps BusinessKit lifecycle states to Pluggable lifecycle states.
  ///
  /// `notRunning` and `launching` collapse to ``FKPluggableAppLifecycleState/terminated`` for DI consumers.
  public static func map(_ state: FKAppLifecycleState) -> FKPluggableAppLifecycleState {
    switch state {
    case .active:
      return .active
    case .inactive:
      return .inactive
    case .background:
      return .background
    case .notRunning, .launching, .terminated:
      return .terminated
    }
  }
}
