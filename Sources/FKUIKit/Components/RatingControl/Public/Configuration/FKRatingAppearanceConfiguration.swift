import UIKit

/// Colors, icons, caption typography, and symbol sizing for ``FKRatingControl``.
public struct FKRatingAppearanceConfiguration: @unchecked Sendable {
  /// Icon source for empty and filled states.
  public var iconStyle: FKRatingIconStyle
  /// Tint applied to empty item glyphs.
  public var emptyColor: UIColor
  /// Tint applied to filled item glyphs.
  public var filledColor: UIColor
  /// Optional symbol weight/scale applied when resolving SF Symbols.
  public var symbolConfiguration: UIImage.SymbolConfiguration?
  /// Rendering mode for resolved images.
  public var renderingMode: UIImage.RenderingMode
  /// Caption font when ``FKRatingLayoutConfiguration/labelPlacement`` is not ``FKRatingLabelPlacement/none``.
  public var labelFont: UIFont
  /// Caption text color.
  public var labelColor: UIColor
  /// Optional formatter for the caption; when `nil` a default one-decimal formatter is used.
  public var valueNumberFormatter: NumberFormatter?

  public init(
    iconStyle: FKRatingIconStyle = .preset(.star),
    emptyColor: UIColor = .tertiaryLabel,
    filledColor: UIColor = .systemYellow,
    symbolConfiguration: UIImage.SymbolConfiguration? = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium),
    renderingMode: UIImage.RenderingMode = .alwaysTemplate,
    labelFont: UIFont = .preferredFont(forTextStyle: .subheadline),
    labelColor: UIColor = .secondaryLabel,
    valueNumberFormatter: NumberFormatter? = nil
  ) {
    self.iconStyle = iconStyle
    self.emptyColor = emptyColor
    self.filledColor = filledColor
    self.symbolConfiguration = symbolConfiguration
    self.renderingMode = renderingMode
    self.labelFont = labelFont
    self.labelColor = labelColor
    self.valueNumberFormatter = valueNumberFormatter
  }
}
