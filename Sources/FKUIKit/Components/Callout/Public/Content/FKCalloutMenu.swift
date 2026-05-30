import UIKit

/// One selectable or actionable row in a callout menu.
///
/// - Note: Marked `@unchecked Sendable` because `UIImage` and `UIColor` are not `Sendable`; treat instances as main-thread snapshots.
public struct FKCalloutMenuItem: @unchecked Sendable, Equatable, Identifiable {
  /// Stable row identifier.
  public var id: String
  /// Primary label.
  public var title: String
  /// Optional secondary line (for example plan tier).
  public var subtitle: String?
  /// Optional template image icon.
  public var icon: UIImage?
  /// Optional SF Symbol name when ``icon`` is `nil`.
  public var symbolName: String?
  /// Shows a trailing checkmark when `true`.
  public var isSelected: Bool
  /// Tint applied to icon and title when set.
  public var tintColor: UIColor?
  /// Whether the row accepts taps.
  public var isEnabled: Bool
  /// Uses destructive emphasis styling.
  public var isDestructive: Bool

  /// Creates a menu item.
  public init(
    id: String = UUID().uuidString,
    title: String,
    subtitle: String? = nil,
    icon: UIImage? = nil,
    symbolName: String? = nil,
    isSelected: Bool = false,
    tintColor: UIColor? = nil,
    isEnabled: Bool = true,
    isDestructive: Bool = false
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.symbolName = symbolName
    self.isSelected = isSelected
    self.tintColor = tintColor
    self.isEnabled = isEnabled
    self.isDestructive = isDestructive
  }
}

/// A group of menu rows separated from adjacent sections by a divider.
public struct FKCalloutMenuSection: Sendable, Equatable {
  /// Rows in this section.
  public var items: [FKCalloutMenuItem]

  /// Creates a section.
  public init(items: [FKCalloutMenuItem]) {
    self.items = items
  }
}

/// Menu payload for dropdown/action popovers (icons, subtitles, selection, section dividers).
public struct FKCalloutMenu: Sendable, Equatable {
  /// Optional non-interactive header label (for example account email).
  public var header: String?
  /// Grouped menu sections.
  public var sections: [FKCalloutMenuSection]

  /// Creates a menu model.
  public init(header: String? = nil, sections: [FKCalloutMenuSection]) {
    self.header = header
    self.sections = sections
  }
}
