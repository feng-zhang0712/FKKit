import UIKit
import FKUIKit

public extension FKFilterBarPresentation {
  /// Visual appearance for bar items (the clickable tabs).
  ///
  /// This is intentionally small and focused:
  /// - Colors and fonts for the title
  /// - Chevron size/spacing
  ///
  /// Panel appearance (mask/corner radius/host, etc.) is configured via `Configuration.presentationConfiguration`.
  struct BarItemAppearance {
    public var normalTitleColor: UIColor
    public var selectedTitleColor: UIColor
    public var normalChevronColor: UIColor
    public var selectedChevronColor: UIColor
    public var titleFont: UIFont
    public var chevronPointSize: CGFloat
    public var chevronSpacing: CGFloat

    public init(
      normalTitleColor: UIColor = .label,
      selectedTitleColor: UIColor = .systemRed,
      normalChevronColor: UIColor = .secondaryLabel,
      selectedChevronColor: UIColor = .systemRed,
      titleFont: UIFont = .preferredFont(forTextStyle: .subheadline),
      chevronPointSize: CGFloat = 11,
      chevronSpacing: CGFloat = 4
    ) {
      self.normalTitleColor = normalTitleColor
      self.selectedTitleColor = selectedTitleColor
      self.normalChevronColor = normalChevronColor
      self.selectedChevronColor = selectedChevronColor
      self.titleFont = titleFont
      self.chevronPointSize = chevronPointSize
      self.chevronSpacing = chevronSpacing
    }
  }

  /// High-level configuration for `FKFilterBarPresentation`.
  ///
  /// - `barItemAppearance`: Controls the tab button look.
  /// - `barConfiguration`: Passed through to `FKBar` (layout/spacing/behavior).
  /// - `presentationConfiguration`: Passed through to `FKPresentation` (mask/layout/corners).
  ///
  /// Tip: Prefer starting from `.default` and tweaking a few fields.
  struct Configuration {
    public var barItemAppearance: BarItemAppearance
    public var barConfiguration: FKBar.Configuration
    public var presentationConfiguration: FKPresentation.Configuration

    public static var `default`: Configuration {
      var barCfg = FKBar.Configuration.default
      barCfg.itemSpacing = 0
      barCfg.arrangement = .around
      barCfg.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
      barCfg.appearance.backgroundColor = .systemBackground
      barCfg.selectionScroll.isEnabled = false
      barCfg.usesDefaultSelectionAppearance = false

      var pres = FKPresentation.Configuration.default
      pres.layout.widthMode = .fullWidth
      pres.layout.horizontalAlignment = .center
      pres.layout.verticalSpacing = 0
      pres.layout.preferBelowSource = true
      pres.layout.allowFlipToAbove = false
      pres.layout.clampToSafeArea = false
      pres.mask.enabled = true
      pres.mask.tapToDismissEnabled = true
      pres.mask.alpha = 0.25
      pres.appearance.backgroundColor = .systemBackground
      pres.appearance.alpha = 1
      pres.appearance.cornerRadius = 10
      pres.appearance.cornerCurve = .continuous
      pres.appearance.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
      pres.appearance.shadow = nil
      pres.content.containerInsets = .zero
      pres.content.fallbackBackgroundColor = .systemBackground

      return Configuration(
        barItemAppearance: .init(),
        barConfiguration: barCfg,
        presentationConfiguration: pres
      )
    }

    public init(
      barItemAppearance: BarItemAppearance = .init(),
      barConfiguration: FKBar.Configuration = Configuration.default.barConfiguration,
      presentationConfiguration: FKPresentation.Configuration = Configuration.default.presentationConfiguration
    ) {
      self.barItemAppearance = barItemAppearance
      self.barConfiguration = barConfiguration
      self.presentationConfiguration = presentationConfiguration
    }
  }
}

