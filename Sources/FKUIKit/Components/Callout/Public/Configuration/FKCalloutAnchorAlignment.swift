import Foundation

/// Aligns the callout bubble relative to the anchor rect along the axis perpendicular to the beak.
public enum FKCalloutAnchorAlignment: Sendable, Equatable {
  /// Centers the bubble on the anchor (default).
  case center
  /// Aligns the bubble's leading/top edge with the anchor's leading/top edge.
  case leading
  /// Aligns the bubble's trailing/bottom edge with the anchor's trailing/bottom edge.
  case trailing
}
