import UIKit

@MainActor
enum FKTabBarLayoutMetrics {
  static func minimumBarHeight(for layout: FKTabBarLayoutConfiguration) -> CGFloat {
    switch layout.hostingContext {
    case .standalone:
      return 44
    case .navigationBarTitleView:
      return 28
    }
  }

  static func resolvedBarHeight(
    layout: FKTabBarLayoutConfiguration,
    appearance: FKTabBarAppearance,
    presentation: FKTabBarResolvedTitlePresentation,
    safeAreaBottomAddition: CGFloat
  ) -> CGFloat {
    let floor = minimumBarHeight(for: layout)
    let preferredBase = layout.preferredBarHeight ?? layout.minimumItemHeight
    let baseHeight = max(floor, preferredBase)
    let verticalInsets = layout.contentInsets.top + layout.contentInsets.bottom

    guard presentation.shouldIncreaseBarHeight else {
      return baseHeight + safeAreaBottomAddition + verticalInsets
    }

    let typography = appearance.typography
    let scaledFont: UIFont = typography.adjustsForContentSizeCategory
      ? UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: typography.selectedFont)
      : typography.selectedFont
    let textHeight = ceil(scaledFont.lineHeight * CGFloat(max(1, presentation.maximumTitleLines)))
    let iconReserve: CGFloat = layout.itemLayoutDirection == .vertical ? 28 : 0
    let preferredHeight = max(baseHeight, textHeight + iconReserve + 24)
    return preferredHeight + safeAreaBottomAddition + verticalInsets
  }
}
