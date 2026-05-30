import Foundation

/// Edge-relative placement of a callout bubble next to its anchor.
///
/// The case name describes where the **bubble** sits relative to the anchor.
/// The beak points toward the anchor on the opposite edge (for example, `.top` places the bubble above the anchor with the arrow on the bottom edge).
///
/// Use ``automatic`` to let the layout engine pick the side with the most room inside the safe area.
public enum FKCalloutPlacement: Sendable, Equatable, CaseIterable {
  /// Chooses among top, bottom, leading, and trailing based on available space (default).
  case automatic
  /// Bubble above the anchor; beak centered on the bottom edge (toward anchor centroid).
  case top
  /// Bubble above the anchor; beak on the bottom edge near the leading corner (toward anchor top-leading).
  case topLeading
  /// Bubble above the anchor; beak on the bottom edge near the trailing corner (toward anchor top-trailing).
  case topTrailing
  /// Bubble below the anchor; beak centered on the top edge.
  case bottom
  /// Bubble below the anchor; beak toward the leading side of the top edge.
  case bottomLeading
  /// Bubble below the anchor; beak toward the trailing side of the top edge.
  case bottomTrailing
  /// Bubble leading the anchor; beak centered on the trailing edge.
  case leading
  /// Bubble leading the anchor; beak toward the top of the trailing edge.
  case leadingTop
  /// Bubble leading the anchor; beak toward the bottom of the trailing edge.
  case leadingBottom
  /// Bubble trailing the anchor; beak centered on the leading edge.
  case trailing
  /// Bubble trailing the anchor; beak toward the top of the leading edge.
  case trailingTop
  /// Bubble trailing the anchor; beak toward the bottom of the leading edge.
  case trailingBottom
}
