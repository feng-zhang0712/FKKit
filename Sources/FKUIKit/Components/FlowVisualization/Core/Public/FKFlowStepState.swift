import Foundation

/// Semantic state of a single step or node in a linear flow.
public enum FKFlowStepState: Sendable, Equatable, Hashable {
  /// Step finished; connector to the next step is filled.
  case completed
  /// Active step; emphasized node and title styling.
  case current
  /// Not yet reached; muted node and connectors.
  case upcoming
  /// Failed or blocked step; destructive styling.
  case error
  /// Intentionally bypassed; muted title; connector may still advance.
  case skipped
  /// Visible but not interactive; reduced opacity.
  case disabled
}
