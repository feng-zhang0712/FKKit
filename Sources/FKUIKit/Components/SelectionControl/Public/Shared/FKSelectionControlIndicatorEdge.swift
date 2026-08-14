import Foundation

/// Semantic edge for the selection indicator within a row.
public enum FKSelectionControlIndicatorEdge: Sendable, Equatable {
  /// Indicator on the leading edge (design default).
  case leading
  /// Indicator on the trailing edge (Settings-style lists).
  case trailing
}
