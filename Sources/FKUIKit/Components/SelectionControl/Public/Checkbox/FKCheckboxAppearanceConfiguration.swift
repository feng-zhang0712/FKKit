import UIKit

/// Colors, typography, and glyphs for ``FKCheckbox``.
public struct FKCheckboxAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var tint: FKSelectionControlTint
  public var uncheckedBorderColor: UIColor
  public var uncheckedBorderWidth: CGFloat?
  public var checkmarkColor: UIColor
  public var checkmarkImage: UIImage?
  public var indeterminateImage: UIImage?
  /// When `nil`, corner radius is derived from size.
  public var cornerRadius: CGFloat?
  public var titleColor: UIColor
  public var subtitleColor: UIColor
  public var disabledTitleColor: UIColor
  public var titleFont: UIFont
  public var subtitleFont: UIFont
  public var errorBorderColor: UIColor
  public var disabledAlpha: CGFloat
  public var pressedAlpha: CGFloat
  public var pressedScale: CGFloat
  public var requiredAsteriskColor: UIColor

  public init(
    tint: FKSelectionControlTint = .blue,
    uncheckedBorderColor: UIColor = .separator,
    uncheckedBorderWidth: CGFloat? = nil,
    checkmarkColor: UIColor = .white,
    checkmarkImage: UIImage? = nil,
    indeterminateImage: UIImage? = nil,
    cornerRadius: CGFloat? = nil,
    titleColor: UIColor = .label,
    subtitleColor: UIColor = .secondaryLabel,
    disabledTitleColor: UIColor = .tertiaryLabel,
    titleFont: UIFont = .preferredFont(forTextStyle: .body),
    subtitleFont: UIFont = .preferredFont(forTextStyle: .footnote),
    errorBorderColor: UIColor = .systemRed,
    disabledAlpha: CGFloat = 0.48,
    pressedAlpha: CGFloat = 0.72,
    pressedScale: CGFloat = 1.0,
    requiredAsteriskColor: UIColor = .systemRed
  ) {
    self.tint = tint
    self.uncheckedBorderColor = uncheckedBorderColor
    self.uncheckedBorderWidth = uncheckedBorderWidth.map { max(0.5, $0) }
    self.checkmarkColor = checkmarkColor
    self.checkmarkImage = checkmarkImage
    self.indeterminateImage = indeterminateImage
    self.cornerRadius = cornerRadius
    self.titleColor = titleColor
    self.subtitleColor = subtitleColor
    self.disabledTitleColor = disabledTitleColor
    self.titleFont = titleFont
    self.subtitleFont = subtitleFont
    self.errorBorderColor = errorBorderColor
    self.disabledAlpha = min(max(0.1, disabledAlpha), 1)
    self.pressedAlpha = min(max(0.1, pressedAlpha), 1)
    self.pressedScale = min(max(0.9, pressedScale), 1)
    self.requiredAsteriskColor = requiredAsteriskColor
  }

  public static func == (lhs: FKCheckboxAppearanceConfiguration, rhs: FKCheckboxAppearanceConfiguration) -> Bool {
    lhs.tint == rhs.tint
      && lhs.uncheckedBorderColor == rhs.uncheckedBorderColor
      && lhs.uncheckedBorderWidth == rhs.uncheckedBorderWidth
      && lhs.checkmarkColor == rhs.checkmarkColor
      && lhs.checkmarkImage === rhs.checkmarkImage
      && lhs.indeterminateImage === rhs.indeterminateImage
      && lhs.cornerRadius == rhs.cornerRadius
      && lhs.titleColor == rhs.titleColor
      && lhs.subtitleColor == rhs.subtitleColor
      && lhs.disabledTitleColor == rhs.disabledTitleColor
      && lhs.titleFont == rhs.titleFont
      && lhs.subtitleFont == rhs.subtitleFont
      && lhs.errorBorderColor == rhs.errorBorderColor
      && lhs.disabledAlpha == rhs.disabledAlpha
      && lhs.pressedAlpha == rhs.pressedAlpha
      && lhs.pressedScale == rhs.pressedScale
      && lhs.requiredAsteriskColor == rhs.requiredAsteriskColor
  }
}
