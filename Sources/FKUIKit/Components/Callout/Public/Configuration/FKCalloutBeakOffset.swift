import Foundation

/// Coordinate system used by ``FKCalloutBeakOffset/fraction(_:reference:)`` and ``fixed(_:reference:)``.
public enum FKCalloutBeakOffsetReference: Sendable, Equatable {
  /// Positions along the bubble beak edge from its leading/top start (respects RTL on horizontal edges).
  case bubbleEdge
  /// Positions relative to the anchor point projected onto the beak edge (centroid or aligned corner).
  case anchor
}

/// Controls where the beak sits along its edge.
///
/// - ``automatic`` uses anchor centroid for cardinal placements (``.top``, ``.bottom``, …) and
///   aligned anchor corners for compound placements (``.topLeading``, ``.bottomTrailing``, …).
/// - Explicit ``fraction`` / ``fixed`` values override placement defaults.
public enum FKCalloutBeakOffset: Sendable, Equatable {
  /// Placement-driven defaults (center vs corner) unless a custom offset is set.
  case automatic
  /// Fraction `0...1` along the usable beak edge.
  case fraction(CGFloat, reference: FKCalloutBeakOffsetReference = .bubbleEdge)
  /// Fixed distance in points from the reference origin on the usable beak edge.
  case fixed(CGFloat, reference: FKCalloutBeakOffsetReference = .bubbleEdge)
}
