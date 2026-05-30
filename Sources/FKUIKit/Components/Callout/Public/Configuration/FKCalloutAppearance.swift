import UIKit

/// Visual chrome for callout bubbles (shared by tooltip and popover presets).
///
/// - Note: Marked `@unchecked Sendable` because `UIColor` is not `Sendable`; treat instances as main-thread configuration snapshots.
public struct FKCalloutAppearance: @unchecked Sendable, Equatable {
  /// High-level light/dark preset.
  public enum Style: Sendable, Equatable {
    /// White surface, dark text, subtle shadow.
    case light
    /// Near-black surface, light text, minimal shadow.
    case dark
  }

  /// Preset style used when explicit colors are `nil`.
  public var style: Style
  /// Fill color override; `nil` uses ``Style`` defaults.
  public var backgroundColor: UIColor?
  /// Primary text color override.
  public var textColor: UIColor?
  /// Secondary text color for title/subtitle bodies.
  public var secondaryTextColor: UIColor?
  /// Continuous corner radius of the rounded body.
  public var cornerRadius: CGFloat
  /// Width of the triangular beak at its base.
  public var beakWidth: CGFloat
  /// Length of the beak from base to tip.
  public var beakHeight: CGFloat
  /// Shape of the beak pointer (isosceles, equilateral, right angle, or custom polygon).
  public var beakStyle: FKCalloutBeakStyle
  /// Inset from the bubble corner when compound placements align the beak to a corner.
  public var beakCornerInset: CGFloat
  /// Enables drop shadow on the bubble layer.
  public var showsShadow: Bool
  /// Shadow opacity when ``showsShadow`` is true.
  public var shadowOpacity: Float
  /// Shadow blur radius.
  public var shadowRadius: CGFloat
  /// Shadow offset.
  public var shadowOffset: CGSize
  /// Optional hairline border color; `nil` hides the border.
  public var borderColor: UIColor?
  /// Border width when ``borderColor`` is set.
  public var borderWidth: CGFloat
  /// When `true`, uses a system material blur behind bubble content (body and beak share the frosted fill).
  public var usesFrostedGlassBackground: Bool

  /// Creates appearance settings.
  public init(
    style: Style = .light,
    backgroundColor: UIColor? = nil,
    textColor: UIColor? = nil,
    secondaryTextColor: UIColor? = nil,
    cornerRadius: CGFloat = 8,
    beakWidth: CGFloat = 14,
    beakHeight: CGFloat = 7,
    beakStyle: FKCalloutBeakStyle = .isosceles,
    beakCornerInset: CGFloat = 12,
    showsShadow: Bool = true,
    shadowOpacity: Float = 0.12,
    shadowRadius: CGFloat = 10,
    shadowOffset: CGSize = CGSize(width: 0, height: 4),
    borderColor: UIColor? = nil,
    borderWidth: CGFloat = 0,
    usesFrostedGlassBackground: Bool = false
  ) {
    self.style = style
    self.backgroundColor = backgroundColor
    self.textColor = textColor
    self.secondaryTextColor = secondaryTextColor
    self.cornerRadius = cornerRadius
    self.beakWidth = beakWidth
    self.beakHeight = beakHeight
    self.beakStyle = beakStyle
    self.beakCornerInset = beakCornerInset
    self.showsShadow = showsShadow
    self.shadowOpacity = shadowOpacity
    self.shadowRadius = shadowRadius
    self.shadowOffset = shadowOffset
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.usesFrostedGlassBackground = usesFrostedGlassBackground
  }

  /// Resolves the background color for the current traits.
  @MainActor
  public func resolvedBackgroundColor(traitCollection: UITraitCollection?) -> UIColor {
    if let backgroundColor {
      return backgroundColor
    }
    switch style {
    case .light:
      return UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.secondarySystemBackground : .white
      }
    case .dark:
      return UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 0.98) : UIColor(white: 0.08, alpha: 0.96)
      }
    }
  }

  /// Resolves primary text color.
  @MainActor
  public func resolvedTextColor(traitCollection: UITraitCollection?) -> UIColor {
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

  /// Resolves secondary text color.
  @MainActor
  public func resolvedSecondaryTextColor(traitCollection: UITraitCollection?) -> UIColor {
    if let secondaryTextColor {
      return secondaryTextColor
    }
    switch style {
    case .light:
      return UIColor.secondaryLabel
    case .dark:
      return UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.82, alpha: 1) : UIColor(white: 0.88, alpha: 1)
      }
    }
  }
}
