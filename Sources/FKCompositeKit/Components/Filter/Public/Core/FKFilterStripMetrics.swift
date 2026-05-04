import UIKit

/// Typography, chevron layout, and optional title/chevron colors for a tab in ``FKFilterTab``.
///
/// Colors map to ``FKAnchoredDropdownTab/chevronTitle(id:itemID:title:subtitle:normalTitleColor:expandedTitleColor:normalChevronColor:expandedChevronColor:titleFont:subtitleFont:chevronSize:chevronSpacing:titleSubtitleSpacing:content:)``.
public struct FKFilterStripMetrics: Sendable {
  public var titleTextStyle: UIFont.TextStyle
  public var subtitleTextStyle: UIFont.TextStyle
  public var chevronSize: CGSize
  public var chevronSpacing: CGFloat
  public var titleSubtitleSpacing: CGFloat
  public var normalTitleColor: UIColor
  public var expandedTitleColor: UIColor
  public var normalChevronColor: UIColor
  public var expandedChevronColor: UIColor

  public init(
    titleTextStyle: UIFont.TextStyle = .subheadline,
    subtitleTextStyle: UIFont.TextStyle = .caption2,
    chevronSize: CGSize = CGSize(width: 14, height: 14),
    chevronSpacing: CGFloat = 4,
    titleSubtitleSpacing: CGFloat = 2,
    normalTitleColor: UIColor = .label,
    expandedTitleColor: UIColor = .tintColor,
    normalChevronColor: UIColor = .secondaryLabel,
    expandedChevronColor: UIColor = .tintColor
  ) {
    self.titleTextStyle = titleTextStyle
    self.subtitleTextStyle = subtitleTextStyle
    self.chevronSize = chevronSize
    self.chevronSpacing = chevronSpacing
    self.titleSubtitleSpacing = titleSubtitleSpacing
    self.normalTitleColor = normalTitleColor
    self.expandedTitleColor = expandedTitleColor
    self.normalChevronColor = normalChevronColor
    self.expandedChevronColor = expandedChevronColor
  }
}
