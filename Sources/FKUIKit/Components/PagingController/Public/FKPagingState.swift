import Foundation

/// High-level transition phase exposed by ``FKPagingController``.
public enum FKPagingPhase: Equatable {
  /// No interactive or programmatic transition is active.
  case idle
  /// User is dragging the internal paging scroll view.
  case dragging
  /// Scroll view is decelerating after a drag.
  case settling
  /// A programmatic page switch (API or tab-driven) is in flight.
  case programmaticSwitch
  /// The current transition was superseded or aborted; selection will reconcile on the next event.
  case interrupted
}

/// Immutable snapshot of ``FKPagingController`` transition state.
public struct FKPagingStateSnapshot: Equatable {
  /// Last settled page index.
  public var selectedIndex: Int
  /// Origin index for an in-flight transition, if applicable.
  public var fromIndex: Int?
  /// Destination index for an in-flight transition, if applicable.
  public var toIndex: Int?
  /// Normalized interactive progress in `0...1` while dragging.
  public var progress: CGFloat
  /// Current phase.
  public var phase: FKPagingPhase
  /// Monotonic token associated with programmatic transitions (for correlating callbacks).
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
