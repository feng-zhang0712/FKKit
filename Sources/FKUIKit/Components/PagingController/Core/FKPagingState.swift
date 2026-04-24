import Foundation

/// Runtime phase for `FKPagingController`.
public enum FKPagingPhase: Equatable {
  /// No active transition.
  case idle
  /// User is dragging the paging scroll view.
  case dragging
  /// Transition is decelerating/settling after a drag.
  case settling
  /// Transition is driven by API or tab tap.
  case programmaticSwitch
  /// Active transition was superseded by a newer request.
  case interrupted
}

/// Immutable state snapshot emitted by the paging state machine.
public struct FKPagingStateSnapshot: Equatable {
  /// Current settled page index.
  public var selectedIndex: Int
  /// Source index for an in-flight transition.
  public var fromIndex: Int?
  /// Target index for an in-flight transition.
  public var toIndex: Int?
  /// Normalized transition progress in `0...1`.
  public var progress: CGFloat
  /// Current phase.
  public var phase: FKPagingPhase
  /// Monotonic token used to reject stale callbacks.
  public var transitionToken: Int

  public init(
    selectedIndex: Int,
    fromIndex: Int? = nil,
    toIndex: Int? = nil,
    progress: CGFloat = 0,
    phase: FKPagingPhase = .idle,
    transitionToken: Int = 0
  ) {
    self.selectedIndex = selectedIndex
    self.fromIndex = fromIndex
    self.toIndex = toIndex
    self.progress = progress
    self.phase = phase
    self.transitionToken = transitionToken
  }
}
