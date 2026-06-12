import UIKit

/// Typography token for CellKit labels, resolved with Dynamic Type via ``UIFontMetrics``.
public struct FKCellTextStyle: Sendable, Equatable {
  /// UIKit text style used when resolving the font.
  public var textStyle: UIFont.TextStyle

  /// Optional weight override applied after scaling.
  public var weight: UIFont.Weight?

  /// Creates a text style token.
  public init(textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil) {
    self.textStyle = textStyle
    self.weight = weight
  }

  /// Body text style (default row title).
  public static let body = FKCellTextStyle(textStyle: .body)

  /// Subheadline style (secondary detail lines).
  public static let subheadline = FKCellTextStyle(textStyle: .subheadline)

  /// Footnote style (section headers and footers).
  public static let footnote = FKCellTextStyle(textStyle: .footnote)

  /// Title2 bold style (hero headings).
  public static let title2Bold = FKCellTextStyle(textStyle: .title2, weight: .bold)

  /// Resolves a scaled font for the current trait collection.
  @MainActor
  public func resolvedFont(compatibleWith traitCollection: UITraitCollection) -> UIFont {
    let metrics = UIFontMetrics(forTextStyle: textStyle)
    let base = UIFont.preferredFont(forTextStyle: textStyle)
    guard let weight else {
      return metrics.scaledFont(for: base, compatibleWith: traitCollection)
    }
    let weighted = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
    return metrics.scaledFont(for: weighted, compatibleWith: traitCollection)
  }
}
