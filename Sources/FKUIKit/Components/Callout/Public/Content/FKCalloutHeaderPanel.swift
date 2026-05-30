import UIKit

/// Colored header card for split popovers (rounded header block + body layouts).
public struct FKCalloutHeaderPanel: Sendable, Equatable {
  /// Header title text.
  public var title: String
  /// Header background override; `nil` uses ``FKCalloutAppearance/Style`` defaults.
  public var backgroundColor: UIColor?
  /// Header text color override.
  public var textColor: UIColor?

  /// Creates a header panel descriptor.
  public init(title: String, backgroundColor: UIColor? = nil, textColor: UIColor? = nil) {
    self.title = title
    self.backgroundColor = backgroundColor
    self.textColor = textColor
  }

  /// Resolves the header background for the current style.
  @MainActor
  public func resolvedBackgroundColor(
    style: FKCalloutAppearance.Style,
    traitCollection: UITraitCollection?
  ) -> UIColor {
    if let backgroundColor {
      return backgroundColor
    }
    switch style {
    case .light:
      return UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.tertiarySystemFill : UIColor.secondarySystemGroupedBackground
      }
    case .dark:
      return UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.08, alpha: 1) : UIColor(white: 0.06, alpha: 1)
      }
    }
  }

  /// Resolves header text color.
  @MainActor
  public func resolvedTextColor(
    style: FKCalloutAppearance.Style,
    traitCollection: UITraitCollection?
  ) -> UIColor {
    if let textColor {
      return textColor
    }
    switch style {
    case .light:
      return UIColor.label
    case .dark:
      return UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(white: 0.98, alpha: 1)
      }
    }
  }
}
