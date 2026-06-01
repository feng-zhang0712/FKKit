import UIKit

@MainActor
enum FKTabBarItemWidthStrategy {
  /// Computes item size for all width/overflow/layout-direction combinations.
  ///
  /// Keeping this logic isolated avoids diverging width behavior between initial layout,
  /// rotation relayout, and incremental updates.
  static func sizeForItem(
    item: FKTabBarItem,
    index: Int,
    visibleItemsCount: Int,
    collectionBounds: CGRect,
    layout: FKTabBarLayoutConfiguration,
    appearance: FKTabBarAppearance,
    effectiveOverflowMode: FKTabBarTitleOverflowMode,
    maximumTitleLines: Int,
    shouldIncreaseHeightForLargeText: Bool,
    customization: FKTabBarCustomization?,
    tabBar: FKTabBar?
  ) -> CGSize {
    // Height is derived from collection bounds and layout insets so rotation/safe-area changes
    // do not require separate code paths. Width is measured from content using the most "expensive"
    // typography state (selected vs normal) to avoid reflow during selection changes.
    let verticalInsets = max(0, layout.contentInsets.top + layout.contentInsets.bottom)
    let itemVerticalInsets = layout.itemInsets.top + layout.itemInsets.bottom
    let availableHeight = max(1, collectionBounds.height - verticalInsets - itemVerticalInsets)
    // Ensure a minimum hit area of 44pt for accessibility and platform conventions.
    var itemHeight = max(44, layout.minimumItemHeight, availableHeight)
    if let tabBar, let custom = customization?.customWidth(for: index, item: item, in: tabBar) {
      // Custom provider is a power feature; keep it cheap because it's queried during layout.
      return CGSize(width: max(32, custom), height: itemHeight)
    }

    let measuredContentSize = FKTabBarItemContentMeasurer.measuredContentSize(
      item: item,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: effectiveOverflowMode,
      maximumTitleLines: maximumTitleLines
    )

    var width = measuredContentSize.width
    if width <= 0 {
      width = legacyEstimatedWidth(for: item, layout: layout, appearance: appearance)
    }
    width += customAccessoryReserve(for: item)
    width = max(44, width)

    if case .fixedWidth(let fixedWidth) = effectiveOverflowMode {
      width = fixedWidth
    }

    if shouldIncreaseHeightForLargeText {
      let preferredHeight = measuredContentSize.height > 0
        ? measuredContentSize.height
        : legacyEstimatedHeight(
          item: item,
          layout: layout,
          appearance: appearance,
          maximumTitleLines: maximumTitleLines
        )
      itemHeight = max(itemHeight, preferredHeight)
    }

    // Fill-equally is authoritative and bypasses content alignment strategies.
    let mode: FKTabBarItemWidthMode = layout.widthMode
    switch mode {
    case .intrinsic:
      break
    case .fixed(let fixed):
      width = fixed
    case .fillEqually:
      let count = max(1, visibleItemsCount)
      let insets = layout.contentInsets.leading + layout.contentInsets.trailing
      let fill = max(44, (collectionBounds.width - insets - layout.itemSpacing * CGFloat(max(0, count - 1))) / CGFloat(count))
      return CGSize(width: fill, height: itemHeight)
    case .constrained(let minWidth, let maxWidth):
      width = min(max(minWidth, width), maxWidth)
    }
    return CGSize(width: width, height: itemHeight)
  }

  private static func customAccessoryReserve(for item: FKTabBarItem) -> CGFloat {
    switch item.accessory.kind {
    case .none, .chevron:
      return 0
    case .custom:
      return max(12, item.accessory.spacing + 12)
    }
  }

  /// Fallback width when ``FKTabBarItem/customContentIdentifier`` prevents button measurement.
  private static func legacyEstimatedWidth(
    for item: FKTabBarItem,
    layout: FKTabBarLayoutConfiguration,
    appearance: FKTabBarAppearance
  ) -> CGFloat {
    let baseText = item.title.normal.text ?? ""
    let measuredTextWidth = legacyMeasuredTextWidth(text: baseText, typography: appearance.typography)
    let imageMetrics = legacyImageMetrics(for: item)
    let horizontalChrome =
      layout.itemInsets.leading
      + layout.itemInsets.trailing
      + imageMetrics.titleSpacing
      + imageMetrics.width
    if layout.itemLayoutDirection == .vertical {
      return max(measuredTextWidth, imageMetrics.width) + layout.itemInsets.leading + layout.itemInsets.trailing
    }
    return measuredTextWidth + horizontalChrome
  }

  private static func legacyEstimatedHeight(
    item: FKTabBarItem,
    layout: FKTabBarLayoutConfiguration,
    appearance: FKTabBarAppearance,
    maximumTitleLines: Int
  ) -> CGFloat {
    let lineCount = max(1, maximumTitleLines)
    let scaledFont: UIFont = appearance.typography.adjustsForContentSizeCategory
      ? UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: appearance.typography.selectedFont)
      : appearance.typography.selectedFont
    let imageMetrics = legacyImageMetrics(for: item)
    let verticalChrome = layout.itemInsets.top + layout.itemInsets.bottom + 12
    let iconReserve: CGFloat = (layout.itemLayoutDirection == .vertical && imageMetrics.width > 0)
      ? imageMetrics.height + imageMetrics.titleSpacing
      : 0
    let textReserve = ceil(scaledFont.lineHeight * CGFloat(lineCount))
    return max(44, layout.minimumItemHeight, textReserve + iconReserve + verticalChrome)
  }

  private static func legacyImageMetrics(for item: FKTabBarItem) -> (width: CGFloat, height: CGFloat, titleSpacing: CGFloat) {
    guard item.image?.normal.source != nil else {
      return (0, 0, 0)
    }
    let style = item.image?.normal.style ?? FKTabBarImageStyle()
    return (style.fixedSize.width, style.fixedSize.height, style.spacingToTitle)
  }

  private static func legacyMeasuredTextWidth(text: String, typography: FKTabBarAppearance.Typography) -> CGFloat {
    guard !text.isEmpty else { return 0 }
    let selectedFont: UIFont = typography.adjustsForContentSizeCategory
      ? UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: typography.selectedFont)
      : typography.selectedFont
    let normalFont: UIFont = typography.adjustsForContentSizeCategory
      ? UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: typography.normalFont)
      : typography.normalFont
    let selectedWidth = ceil((text as NSString).size(withAttributes: [.font: selectedFont]).width)
    let normalWidth = ceil((text as NSString).size(withAttributes: [.font: normalFont]).width)
    return max(selectedWidth, normalWidth)
  }
}
