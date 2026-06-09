import UIKit

/// Layout and timestamp settings for ``FKTimeline``.
public struct FKTimelineLayoutConfiguration: @unchecked Sendable, Equatable {
  /// Vertical layout variant.
  public var layout: FKTimelineLayout
  /// Content insets around rows.
  public var contentInsets: UIEdgeInsets
  /// Vertical spacing between rows.
  public var rowSpacing: CGFloat
  /// Horizontal gap between rail and text block.
  public var railSpacing: CGFloat
  /// Title line limit.
  public var titleNumberOfLines: Int
  /// Subtitle line limit.
  public var subtitleNumberOfLines: Int
  /// Caption line limit.
  public var captionNumberOfLines: Int
  /// Timestamp display mode.
  public var timestampStyle: FKTimelineTimestampStyle
  /// Connector continuation below the last node.
  public var tailStyle: FKTimelineTailStyle
  /// Section header font when ``FKTimeline/sections`` is used.
  public var sectionTitleFont: UIFont
  /// Section header color.
  public var sectionTitleColor: UIColor
  /// When `false`, leading rail stays visually leading even in RTL.
  public var respectInterfaceLayoutDirection: Bool
  /// Enables internal scrolling instead of growing with content.
  public var scrollable: Bool

  public init(
    layout: FKTimelineLayout = .verticalLeadingRail,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12),
    rowSpacing: CGFloat = 0,
    railSpacing: CGFloat = 12,
    titleNumberOfLines: Int = 2,
    subtitleNumberOfLines: Int = 2,
    captionNumberOfLines: Int = 4,
    timestampStyle: FKTimelineTimestampStyle = .absolute,
    tailStyle: FKTimelineTailStyle = .none,
    sectionTitleFont: UIFont = .preferredFont(forTextStyle: .headline),
    sectionTitleColor: UIColor = .secondaryLabel,
    respectInterfaceLayoutDirection: Bool = true,
    scrollable: Bool = false
  ) {
    self.layout = layout
    self.contentInsets = contentInsets
    self.rowSpacing = max(0, rowSpacing)
    self.railSpacing = max(4, railSpacing)
    self.titleNumberOfLines = max(1, titleNumberOfLines)
    self.subtitleNumberOfLines = max(1, subtitleNumberOfLines)
    self.captionNumberOfLines = max(1, captionNumberOfLines)
    self.timestampStyle = timestampStyle
    self.tailStyle = tailStyle
    self.sectionTitleFont = sectionTitleFont
    self.sectionTitleColor = sectionTitleColor
    self.respectInterfaceLayoutDirection = respectInterfaceLayoutDirection
    self.scrollable = scrollable
  }
}
