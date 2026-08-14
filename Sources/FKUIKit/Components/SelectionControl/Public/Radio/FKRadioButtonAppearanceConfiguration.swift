import UIKit

/// Colors and ring metrics for ``FKRadioButton``.
public struct FKRadioButtonAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var tint: FKSelectionControlTint
  public var uncheckedBorderColor: UIColor
  public var ringWidth: CGFloat?
  public var innerDotScale: CGFloat
  /// Selected presentation style. Currently only ``FKRadioSelectedFillStyle/ringAndDot`` is drawn (design default).
  public var selectedFillStyle: FKRadioSelectedFillStyle
  public var titleColor: UIColor
  public var subtitleColor: UIColor
  public var disabledTitleColor: UIColor
  public var titleFont: UIFont
  public var subtitleFont: UIFont
  public var errorBorderColor: UIColor
  public var disabledAlpha: CGFloat
  public var pressedAlpha: CGFloat
  public var pressedScale: CGFloat

  public init(
    tint: FKSelectionControlTint = .blue,
    uncheckedBorderColor: UIColor = .separator,
    ringWidth: CGFloat? = nil,
    innerDotScale: CGFloat = 0.5,
    selectedFillStyle: FKRadioSelectedFillStyle = .ringAndDot,
    titleColor: UIColor = .label,
    subtitleColor: UIColor = .secondaryLabel,
    disabledTitleColor: UIColor = .tertiaryLabel,
    titleFont: UIFont = .preferredFont(forTextStyle: .body),
    subtitleFont: UIFont = .preferredFont(forTextStyle: .footnote),
    errorBorderColor: UIColor = .systemRed,
    disabledAlpha: CGFloat = 0.48,
    pressedAlpha: CGFloat = 0.72,
    pressedScale: CGFloat = 1.0
  ) {
    self.tint = tint
    self.uncheckedBorderColor = uncheckedBorderColor
    self.ringWidth = ringWidth.map { max(0.5, $0) }
    self.innerDotScale = min(max(0.35, innerDotScale), 0.6)
    self.selectedFillStyle = selectedFillStyle
    self.titleColor = titleColor
    self.subtitleColor = subtitleColor
    self.disabledTitleColor = disabledTitleColor
    self.titleFont = titleFont
    self.subtitleFont = subtitleFont
    self.errorBorderColor = errorBorderColor
    self.disabledAlpha = min(max(0.1, disabledAlpha), 1)
    self.pressedAlpha = min(max(0.1, pressedAlpha), 1)
    self.pressedScale = min(max(0.9, pressedScale), 1)
  }
}
