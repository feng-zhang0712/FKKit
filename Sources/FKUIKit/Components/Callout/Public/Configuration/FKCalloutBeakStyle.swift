import CoreGraphics
import Foundation

/// Describes the triangular (or polygon) pointer rendered on a callout bubble edge.
public enum FKCalloutBeakStyle: Sendable, Equatable {
  /// Symmetric triangle using ``FKCalloutAppearance/beakWidth`` and ``beakHeight`` (default).
  case isosceles
  /// Equilateral triangle; height is derived from ``beakWidth`` when ``beakHeight`` is not overridden.
  case equilateral
  /// Right triangle with the right angle on the bubble edge.
  ///
  /// - Parameters:
  ///   - corner: Which end of the beak base hosts the right angle.
  ///   - apexAlongBase: Where the tip sits along the base (`0` = leading/top of base, `1` = trailing/bottom).
  case rightAngle(corner: FKCalloutBeakRightAngleCorner, apexAlongBase: CGFloat = 1)
  /// Custom polygon in normalized beak space.
  ///
  /// Coordinates are relative to the beak slot: `x` is `0...1` along the bubble edge,
  /// `y` is `0` on the bubble edge and `1` at the outward tip. Provide at least three points.
  case polygon(vertices: [CGPoint])
}

/// Which end of the beak base carries the right angle for ``FKCalloutBeakStyle/rightAngle(corner:apexAlongBase:)``.
public enum FKCalloutBeakRightAngleCorner: Sendable, Equatable {
  /// Right angle at the leading/top end of the beak base (LTR leading edge).
  case leading
  /// Right angle at the trailing/bottom end of the beak base.
  case trailing
}
