import UIKit

/// Visual styling for action sheet chrome and rows.
public struct FKActionSheetAppearance: Equatable, Sendable {
  /// Table separator style between rows in a group.
  public enum SeparatorStyle: Sendable, Equatable {
    /// Uses a single line separator, matching grouped `UITableView` defaults.
    case automatic
    case none
    case singleLine
  }

  /// Minimum row height (HIG recommends at least 44pt touch targets).
  public var minimumRowHeight: CGFloat
  /// Extra spacing between the last action group and the cancel group.
  public var cancelGroupSpacing: CGFloat
  /// Horizontal padding inside each row.
  public var rowHorizontalPadding: CGFloat
  /// Row content alignment.
  public var rowAlignment: FKActionSheetRowAlignment
  /// Separator rendering between rows.
  public var separatorStyle: SeparatorStyle
  /// Separator color when visible.
  public var separatorColor: UIColor
  /// Background shown while the row is highlighted.
  public var rowHighlightColor: UIColor
  /// Title font in the header block.
  public var headerTitleFont: UIFont
  /// Message font in the header block.
  public var headerMessageFont: UIFont
  /// Primary action title font.
  public var actionTitleFont: UIFont
  /// Cancel row title font (defaults to semibold system 17).
  public var cancelTitleFont: UIFont
  /// Subtitle font below action titles.
  public var actionSubtitleFont: UIFont
  /// Default action title color.
  public var actionTitleColor: UIColor
  /// Destructive action title color.
  public var destructiveTitleColor: UIColor
  /// Cancel action title color.
  public var cancelTitleColor: UIColor
  /// Disabled action title color.
  public var disabledTitleColor: UIColor
  /// Subtitle text color.
  public var subtitleColor: UIColor
  /// Header title color.
  public var headerTitleColor: UIColor
  /// Header message color.
  public var headerMessageColor: UIColor
  /// Leading symbol tint.
  public var iconTintColor: UIColor
  /// Tint for unselected radio rows and selection icons when ``selectedTitleColor`` is not used.
  public var checkmarkTintColor: UIColor
  /// Accent color for selected rows (title highlight and check / radio icons).
  public var selectedTitleColor: UIColor
  /// Table / scroll background behind grouped cells.
  public var backgroundColor: UIColor
  /// Grouped cell background.
  public var cellBackgroundColor: UIColor
  /// Section header title font.
  public var sectionTitleFont: UIFont
  /// Section header text color.
  public var sectionTitleColor: UIColor
  /// Default VoiceOver hint for destructive rows when none is provided on the action.
  public var destructiveAccessibilityHint: String

  /// System-like defaults suitable for light and dark mode.
  public static let `default` = FKActionSheetAppearance()

  /// Creates appearance settings.
  public init(
    minimumRowHeight: CGFloat = 48,
    cancelGroupSpacing: CGFloat = 8,
    rowHorizontalPadding: CGFloat = 0,
    rowAlignment: FKActionSheetRowAlignment = .center,
    separatorStyle: SeparatorStyle = .automatic,
    separatorColor: UIColor = .separator,
    rowHighlightColor: UIColor = .systemGray5,
    headerTitleFont: UIFont = .systemFont(ofSize: 13, weight: .semibold),
    headerMessageFont: UIFont = .systemFont(ofSize: 13),
    actionTitleFont: UIFont = .systemFont(ofSize: 17),
    cancelTitleFont: UIFont = .systemFont(ofSize: 17, weight: .semibold),
    actionSubtitleFont: UIFont = .systemFont(ofSize: 13),
    actionTitleColor: UIColor = .label,
    destructiveTitleColor: UIColor = .systemRed,
    cancelTitleColor: UIColor = .label,
    disabledTitleColor: UIColor = .tertiaryLabel,
    subtitleColor: UIColor = .secondaryLabel,
    headerTitleColor: UIColor = .secondaryLabel,
    headerMessageColor: UIColor = .secondaryLabel,
    iconTintColor: UIColor = .label,
    checkmarkTintColor: UIColor = .label,
    selectedTitleColor: UIColor = .systemBlue,
    backgroundColor: UIColor = .systemBackground,
    cellBackgroundColor: UIColor = .systemBackground,
    sectionTitleFont: UIFont = .systemFont(ofSize: 13),
    sectionTitleColor: UIColor = .secondaryLabel,
    destructiveAccessibilityHint: String = "This action cannot be undone."
  ) {
    self.minimumRowHeight = max(44, minimumRowHeight)
    self.cancelGroupSpacing = max(0, cancelGroupSpacing)
    self.rowHorizontalPadding = max(0, rowHorizontalPadding)
    self.rowAlignment = rowAlignment
    self.separatorStyle = separatorStyle
    self.separatorColor = separatorColor
    self.rowHighlightColor = rowHighlightColor
    self.headerTitleFont = headerTitleFont
    self.headerMessageFont = headerMessageFont
    self.actionTitleFont = actionTitleFont
    self.cancelTitleFont = cancelTitleFont
    self.actionSubtitleFont = actionSubtitleFont
    self.actionTitleColor = actionTitleColor
    self.destructiveTitleColor = destructiveTitleColor
    self.cancelTitleColor = cancelTitleColor
    self.disabledTitleColor = disabledTitleColor
    self.subtitleColor = subtitleColor
    self.headerTitleColor = headerTitleColor
    self.headerMessageColor = headerMessageColor
    self.iconTintColor = iconTintColor
    self.checkmarkTintColor = checkmarkTintColor
    self.selectedTitleColor = selectedTitleColor
    self.backgroundColor = backgroundColor
    self.cellBackgroundColor = cellBackgroundColor
    self.sectionTitleFont = sectionTitleFont
    self.sectionTitleColor = sectionTitleColor
    self.destructiveAccessibilityHint = destructiveAccessibilityHint
  }
}

/// Process-wide defaults applied when constructing new action sheets.
public enum FKActionSheetGlobalStyle {
  /// Default appearance merged into each `FKActionSheetConfiguration` unless overridden.
  public nonisolated(unsafe) static var appearance: FKActionSheetAppearance = .default
  /// Default appearance preset when callers do not override `appearance`.
  public nonisolated(unsafe) static var appearancePreset: FKActionSheetAppearancePreset = .system
}
