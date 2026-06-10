import UIKit

/// Shared attachment offsets for composite widgets (avatar presence, badge-adjacent overlays).
enum FKWidgetLayoutMetrics {
  /// Bottom-trailing offset for a presence indicator relative to an avatar's visual bounds.
  ///
  /// Mirrors horizontally under RTL layout direction.
  static func presenceIndicatorOffset(
    avatarDiameter: CGFloat,
    indicatorDiameter: CGFloat,
    isRTL: Bool
  ) -> UIOffset {
    let inset = max(0, (avatarDiameter - indicatorDiameter) * 0.08)
    let horizontal = inset + 2
    let vertical = inset + 2
    if isRTL {
      return UIOffset(horizontal: -horizontal, vertical: vertical)
    }
    return UIOffset(horizontal: horizontal, vertical: vertical)
  }

  /// Default ``FKBadge`` offset for ``FKIconView``-sized targets at ``FKBadgeAnchor/topTrailing``.
  ///
  /// Horizontal sign follows badge convention (negative moves outward on the trailing edge in LTR).
  static func iconViewBadgeOffset(side: CGFloat) -> UIOffset {
    let inset = max(2, side * 0.12)
    return UIOffset(horizontal: -inset, vertical: inset)
  }
}
