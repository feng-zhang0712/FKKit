import UIKit

/// Colors for ``FKRadioGroup`` chrome and rows.
public struct FKRadioGroupAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var tint: FKSelectionControlTint
  public var cardBackgroundColor: UIColor
  public var cardBorderColor: UIColor
  public var cardBorderWidth: CGFloat
  public var separatorColor: UIColor
  public var errorBorderColor: UIColor
  public var headerFont: UIFont
  public var footerFont: UIFont
  public var headerColor: UIColor
  public var footerColor: UIColor
  public var titleColor: UIColor
  public var subtitleColor: UIColor
  public var disabledTitleColor: UIColor
  public var titleFont: UIFont
  public var subtitleFont: UIFont
  public var disabledAlpha: CGFloat
  public var pressedAlpha: CGFloat
  public var uncheckedBorderColor: UIColor

  public init(
    tint: FKSelectionControlTint = .blue,
    cardBackgroundColor: UIColor = .secondarySystemGroupedBackground,
    cardBorderColor: UIColor = .separator,
    cardBorderWidth: CGFloat = 1,
    separatorColor: UIColor = .separator,
    errorBorderColor: UIColor = .systemRed,
    headerFont: UIFont = .preferredFont(forTextStyle: .footnote),
    footerFont: UIFont = .preferredFont(forTextStyle: .footnote),
    headerColor: UIColor = .secondaryLabel,
    footerColor: UIColor = .secondaryLabel,
    titleColor: UIColor = .label,
    subtitleColor: UIColor = .secondaryLabel,
    disabledTitleColor: UIColor = .tertiaryLabel,
    titleFont: UIFont = .preferredFont(forTextStyle: .body),
    subtitleFont: UIFont = .preferredFont(forTextStyle: .footnote),
    disabledAlpha: CGFloat = 0.48,
    pressedAlpha: CGFloat = 0.72,
    uncheckedBorderColor: UIColor = .separator
  ) {
    self.tint = tint
    self.cardBackgroundColor = cardBackgroundColor
    self.cardBorderColor = cardBorderColor
    self.cardBorderWidth = max(0, cardBorderWidth)
    self.separatorColor = separatorColor
    self.errorBorderColor = errorBorderColor
    self.headerFont = headerFont
    self.footerFont = footerFont
    self.headerColor = headerColor
    self.footerColor = footerColor
    self.titleColor = titleColor
    self.subtitleColor = subtitleColor
    self.disabledTitleColor = disabledTitleColor
    self.titleFont = titleFont
    self.subtitleFont = subtitleFont
    self.disabledAlpha = min(max(0.1, disabledAlpha), 1)
    self.pressedAlpha = min(max(0.1, pressedAlpha), 1)
    self.uncheckedBorderColor = uncheckedBorderColor
  }
}
