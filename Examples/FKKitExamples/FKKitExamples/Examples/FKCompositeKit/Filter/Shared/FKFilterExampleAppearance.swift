import UIKit
import FKCompositeKit
import FKUIKit

/// Shared tab bar + chevron metrics for Filter examples.
enum FKFilterExampleAppearance {
  /// Total height for the embedded ``FKFilterController`` chrome row (was 56; −4pt).
  static let filterStripChromeHeight: CGFloat = 52

  /// Selected chip / grid label color in filter panels (`FKFilterPillStyle` default); strip expanded tab uses the same.
  private static let filterSelectionAccentColor = UIColor.systemRed

  static let panelPillStyle = FKFilterPillStyle(
    cornerRadius: 6,
    contentInsets: .init(top: 6, left: 8, bottom: 6, right: 8),
    selectedTextColor: filterSelectionAccentColor,
    selectedBackgroundColor: filterSelectionAccentColor.withAlphaComponent(0.10),
    selectedBorderColor: filterSelectionAccentColor.withAlphaComponent(0.55)
  )

  /// Right column / single-column list rows (white background).
  static let panelListCellStyle = FKFilterListCellStyle()

  /// Left sidebar in two-column panels; matches ``FKFilterTwoColumnGridViewController`` default sidebar coloring.
  static let panelSidebarListCellStyle = FKFilterListCellStyle(
    rowBackgroundColor: UIColor.systemGray6.withAlphaComponent(0.6),
    selectedRowBackgroundColor: .systemBackground
  )

  static let titleStyle: UIFont.TextStyle = .subheadline
  static let subtitleStyle: UIFont.TextStyle = .caption2
  static let chevronSize = CGSize(width: 14, height: 14)
  static let chevronSpacing: CGFloat = 4
  static let titleSubtitleSpacing: CGFloat = 2

  static var filterTabStrip: FKFilterTabStripConfiguration {
    FKFilterTabStripConfiguration(
      titleTextStyle: titleStyle,
      subtitleTextStyle: subtitleStyle,
      chevronSize: chevronSize,
      chevronSpacing: chevronSpacing,
      titleSubtitleSpacing: titleSubtitleSpacing,
      expandedTitleColor: filterSelectionAccentColor,
      expandedChevronColor: filterSelectionAccentColor
    )
  }

  /// ``FKFilterController`` defaults for the six-tab hub example.
  static func makeHubFilterConfiguration() -> FKFilterConfiguration<String> {
    FKFilterConfiguration(
      anchoredDropdown: hubAnchoredConfiguration(),
      defaultTabStrip: filterTabStrip,
      panelLoadingTitle: "Loading…"
    )
  }

  /// ``FKFilterController`` defaults for equal-width tab examples.
  static func makeEqualThreeFilterConfiguration() -> FKFilterConfiguration<String> {
    FKFilterConfiguration(
      anchoredDropdown: equalThreeAnchoredConfiguration(),
      defaultTabStrip: filterTabStrip,
      panelLoadingTitle: "Loading…"
    )
  }

  /// Six-tab hub: intrinsic tab widths (horizontal scroll), so long titles are not clipped.
  static func hubAnchoredConfiguration() -> FKAnchoredDropdownConfiguration {
    var cfg = FKAnchoredDropdownConfiguration.default
    cfg.tabBarConfiguration.layout.isScrollable = true
    cfg.tabBarConfiguration.layout.widthMode = .intrinsic
    cfg.tabBarConfiguration.layout.itemSpacing = 4
    cfg.tabBarConfiguration.layout.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
    cfg.tabBarConfiguration.layout.contentAlignment = .leading
    cfg.applyTintOnlyChevronTabTypography(textStyle: .subheadline)
    return cfg
  }

  /// Three tabs: equal width, no horizontal scroll.
  static func equalThreeAnchoredConfiguration() -> FKAnchoredDropdownConfiguration {
    var cfg = FKAnchoredDropdownConfiguration.default
    cfg.tabBarConfiguration.layout.isScrollable = false
    cfg.tabBarConfiguration.layout.widthMode = .fillEqually
    cfg.tabBarConfiguration.layout.itemSpacing = 0
    cfg.tabBarConfiguration.layout.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
    cfg.applyTintOnlyChevronTabTypography(textStyle: .subheadline)
    return cfg
  }

  // MARK: - Anchored dropdown variants (dropdown examples)

  static func makeFilterConfiguration(anchored: FKAnchoredDropdownConfiguration) -> FKFilterConfiguration<String> {
    FKFilterConfiguration(
      anchoredDropdown: anchored,
      defaultTabStrip: filterTabStrip,
      panelLoadingTitle: "Loading…"
    )
  }

  /// Same tab strip as equal-three, but each tab switch dismisses and re-presents the panel shell.
  static func equalThreeDismissThenPresent() -> FKAnchoredDropdownConfiguration {
    var cfg = equalThreeAnchoredConfiguration()
    cfg.switchAnimationStyle = .dismissThenPresent(dismissAnimated: true, presentAnimated: true)
    return cfg
  }

  /// Vertical slide when swapping tabs in place.
  static func equalThreeSlideVerticalSwitch() -> FKAnchoredDropdownConfiguration {
    var cfg = equalThreeAnchoredConfiguration()
    cfg.switchAnimationStyle = .replaceInPlace(animation: .slideVertical(direction: .down, duration: 0.22))
    return cfg
  }

  /// Darker dimming behind the anchored panel.
  static func equalThreeStrongBackdrop() -> FKAnchoredDropdownConfiguration {
    var cfg = equalThreeAnchoredConfiguration()
    cfg.presentationConfiguration.backdropStyle = .dim(alpha: 0.52)
    return cfg
  }

  /// Invisible dim + passthrough hits on the presenting screen (see ``FKPresentationConfiguration/ZeroDimBackdropBehavior``).
  static func equalThreePassthroughBackdrop() -> FKAnchoredDropdownConfiguration {
    var cfg = equalThreeAnchoredConfiguration()
    cfg.presentationConfiguration.backdropStyle = .dim(alpha: 0)
    cfg.presentationConfiguration.zeroDimBackdropBehavior = .passthrough
    cfg.presentationConfiguration.backgroundInteraction = .init(isEnabled: true, showsBackdropWhenEnabled: false)
    return cfg
  }

  /// Rebuilds panel view controllers whenever a tab is opened (no per-tab cache).
  static func equalThreeRecreateContent() -> FKAnchoredDropdownConfiguration {
    var cfg = equalThreeAnchoredConfiguration()
    cfg.contentCachingPolicy = .recreate
    return cfg
  }

  /// Slower relayout when ``preferredContentSize`` changes (e.g. two-column panels).
  static func equalThreeSlowLayoutAnimation() -> FKAnchoredDropdownConfiguration {
    var cfg = equalThreeAnchoredConfiguration()
    cfg.presentationLayoutAnimation = .init(duration: 0.42)
    return cfg
  }
}
