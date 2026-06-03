import UIKit

/// Measures tab item content using the same ``FKButton`` layout path as ``FKTabBarItemCell``.
@MainActor
enum FKTabBarItemContentMeasurer {
  private static let prototype: FKButton = {
    let button = FKButton()
    button.contentHorizontalAlignment = .center
    button.contentVerticalAlignment = .center
    return button
  }()

  /// Returns the laid-out ``FKButton`` size for a tab item, including ``FKTabBarLayoutConfiguration/itemInsets``.
  static func measuredContentSize(
    item: FKTabBarItem,
    index: Int,
    selectedIndex: Int?,
    layout: FKTabBarLayoutConfiguration,
    appearance: FKTabBarAppearance,
    effectiveOverflowMode: FKTabBarTitleOverflowMode,
    maximumTitleLines: Int
  ) -> CGSize {
    guard item.customContentIdentifier == nil else { return .zero }

    let measureAsSelected: Bool = {
      switch layout.intrinsicWidthMeasurement {
      case .normalStateOnly:
        return false
      case .adjustsOnSelection:
        return index == selectedIndex
      }
    }()

    let primarySize = measurePrototypeSize(
      item: item,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: effectiveOverflowMode,
      maximumTitleLines: maximumTitleLines,
      isSelected: measureAsSelected
    )
    guard primarySize.width > 0 else { return .zero }

    guard layout.intrinsicWidthMeasurement == .normalStateOnly,
          item.title.selected != nil else {
      return primarySize
    }

    let selectedSize = measurePrototypeSize(
      item: item,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: effectiveOverflowMode,
      maximumTitleLines: maximumTitleLines,
      isSelected: true
    )
    return CGSize(
      width: max(primarySize.width, selectedSize.width),
      height: max(primarySize.height, selectedSize.height)
    )
  }

  private static func measurePrototypeSize(
    item: FKTabBarItem,
    layout: FKTabBarLayoutConfiguration,
    appearance: FKTabBarAppearance,
    effectiveOverflowMode: FKTabBarTitleOverflowMode,
    maximumTitleLines: Int,
    isSelected: Bool
  ) -> CGSize {
    configurePrototype(
      item: item,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: effectiveOverflowMode,
      maximumTitleLines: maximumTitleLines,
      isSelected: isSelected
    )
    prototype.isSelected = isSelected
    let size = prototype.intrinsicContentSize
    guard size.width > 0, size.width != UIView.noIntrinsicMetric else { return .zero }
    return CGSize(
      width: ceil(size.width),
      height: ceil(max(size.height, 0))
    )
  }

  private static func configurePrototype(
    item: FKTabBarItem,
    layout: FKTabBarLayoutConfiguration,
    appearance: FKTabBarAppearance,
    effectiveOverflowMode: FKTabBarTitleOverflowMode,
    maximumTitleLines: Int,
    isSelected: Bool
  ) {
    FKTabBarItemButtonConfigurator.applyLayoutDirection(layout.itemLayoutDirection, to: prototype)
    let kind = FKTabBarItemButtonConfigurator.resolvedContentKind(for: item)
    FKTabBarItemButtonConfigurator.applyContentKind(kind, to: prototype, item: item, customization: nil)
    FKTabBarItemButtonConfigurator.applyItemInsets(layout.itemInsets, to: prototype)

    let titleText = item.title.resolved(isSelected: isSelected, isEnabled: item.isEnabled).text ?? ""
    let titleFont = FKTabBarItemButtonConfigurator.widerTitleFont(for: titleText, typography: appearance.typography)
    let (lineBreakMode, adjustsFontSizeToFitWidth, minimumScaleFactor) = FKTabBarItemButtonConfigurator.resolvedTitleLayout(
      titleText: titleText,
      overflowMode: effectiveOverflowMode
    )

    let label = FKButton.LabelAttributes(
      text: titleText,
      font: titleFont,
      color: appearance.colors.normalText,
      alignment: .center,
      numberOfLines: max(1, maximumTitleLines),
      lineBreakMode: lineBreakMode,
      adjustsFontForContentSizeCategory: appearance.typography.adjustsForContentSizeCategory,
      textStyle: .subheadline,
      adjustsFontSizeToFitWidth: adjustsFontSizeToFitWidth,
      minimumScaleFactor: minimumScaleFactor
    )
    prototype.setTitle(label, for: .normal)
    prototype.setTitle(label, for: .selected)
    prototype.setTitle(label, for: .disabled)

    applySubtitleIfNeeded(for: item, appearance: appearance, isSelected: isSelected)
    applyAccessoryIfNeeded(for: item, textColor: appearance.colors.normalText)
  }

  private static func applySubtitleIfNeeded(
    for item: FKTabBarItem,
    appearance: FKTabBarAppearance,
    isSelected: Bool
  ) {
    guard let configuration = FKTabBarItemButtonConfigurator.resolvedSubtitleConfiguration(for: item, appearance: appearance),
          let attrs = FKTabBarItemButtonConfigurator.subtitleLabelAttributes(
            from: configuration,
            isSelected: isSelected,
            isEnabled: item.isEnabled,
            spacingToTitle: configuration.spacingToNextText
          ) else {
      prototype.setSubtitle(nil, for: .normal)
      prototype.setSubtitle(nil, for: .selected)
      prototype.setSubtitle(nil, for: .disabled)
      return
    }
    prototype.setSubtitle(attrs, for: .normal)
    prototype.setSubtitle(attrs, for: .selected)
    prototype.setSubtitle(attrs, for: .disabled)
  }

  private static func applyAccessoryIfNeeded(for item: FKTabBarItem, textColor: UIColor) {
    guard let icon = item.accessoryIcon else { return }
    FKTabBarItemButtonConfigurator.applyIconAccessory(
      to: prototype,
      icon: icon,
      textColor: textColor
    )
  }
}
