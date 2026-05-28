import UIKit

/// How single-select clears other rows when the user picks one option in the right column of
/// ``FKFilterTwoColumnListViewController`` or ``FKFilterTwoColumnGridViewController``.
public enum FKFilterTwoColumnSingleSelectionScope: Hashable, Sendable {
  /// Only the tapped section’s selection changes; other sections keep their picks.
  case withinSection
  /// One selected row across all right-hand sections (catalog-style).
  case globalAcrossSections
}

/// Typography and insets for titled section headers on the right column (list table headers and grid supplementary views).
public struct FKFilterTwoColumnRightHeaderStyle {
  public var normalTextColor: UIColor
  public var selectedTextColor: UIColor
  public var font: UIFont
  public var contentInsets: UIEdgeInsets
  public var minimumHeight: CGFloat

  public init(
    normalTextColor: UIColor = .label,
    selectedTextColor: UIColor = .systemRed,
    font: UIFont = {
      let base = UIFont.preferredFont(forTextStyle: .subheadline)
      return UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
    }(),
    contentInsets: UIEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8),
    minimumHeight: CGFloat = 36
  ) {
    self.normalTextColor = normalTextColor
    self.selectedTextColor = selectedTextColor
    self.font = font
    self.contentInsets = contentInsets
    self.minimumHeight = minimumHeight
  }
}
