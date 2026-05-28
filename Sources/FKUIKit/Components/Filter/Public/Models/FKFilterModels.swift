import Foundation

/// Stable identifier for filter rows, sections, and categories.
public struct FKFilterID: Hashable, Sendable, RawRepresentable {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
}

/// Single vs multiple selection for a section.
public enum FKFilterSelectionMode: Sendable {
  case single
  case multiple

  /// Combines tab-level multi-select with each section’s ``FKFilterSection/selectionMode``.
  public static func effective(
    requested: FKFilterSelectionMode,
    allowsMultipleFromTab: Bool
  ) -> FKFilterSelectionMode {
    (allowsMultipleFromTab && requested == .multiple) ? .multiple : .single
  }
}

/// How taps on a **titled** right-hand section header behave in ``FKFilterTwoColumnListViewController`` and
/// ``FKFilterTwoColumnGridViewController``.
///
/// Modes are mutually exclusive: pick exactly one. ``standard`` matches passive UIKit section titles on the list panel
/// (or a non-interactive collection header on the grid).
public enum FKFilterTwoColumnRightSectionHeaderBehavior: Sendable, Hashable {
  /// Title only; header is not interactive.
  case standard
  /// Tap toggles ``FKFilterSection/isCollapsed`` for that section.
  case togglesSectionCollapse
  /// Tap selects the section as a header row: clears item selections and forwards ``FKFilterPanelSelection``.
  case selectableSectionHeader
}

/// Payload emitted by a panel when the user changes the selection (before host adds tab id / panel kind).
public struct FKFilterPanelSelection: Sendable {
  public let sectionID: FKFilterID?
  public let item: FKFilterOptionItem
  public let effectiveSelectionMode: FKFilterSelectionMode

  public init(sectionID: FKFilterID?, item: FKFilterOptionItem, effectiveSelectionMode: FKFilterSelectionMode) {
    self.sectionID = sectionID
    self.item = item
    self.effectiveSelectionMode = effectiveSelectionMode
  }
}

/// Full selection event for a strip tab (after the panel model has been updated).
public struct FKFilterSelectionContext<TabID: Hashable> {
  public let tabID: TabID
  public let panelKind: FKFilterPanelKind
  public let sectionID: FKFilterID?
  public let item: FKFilterOptionItem
  public let effectiveSelectionMode: FKFilterSelectionMode

  public init(tabID: TabID, panelKind: FKFilterPanelKind, selection: FKFilterPanelSelection) {
    self.tabID = tabID
    self.panelKind = panelKind
    self.sectionID = selection.sectionID
    self.item = selection.item
    self.effectiveSelectionMode = selection.effectiveSelectionMode
  }
}

/// One selectable row, chip, or grid cell in a filter panel.
public struct FKFilterOptionItem: Hashable, Sendable {
  public let id: FKFilterID
  public var title: String
  public var subtitle: String?
  /// Rich text title used when present; plain `title` acts as fallback.
  public var attributedTitle: AttributedString?
  /// Rich text subtitle used when present; plain `subtitle` acts as fallback.
  public var attributedSubtitle: AttributedString?
  public var isSelected: Bool
  public var isEnabled: Bool

  public init(
    id: FKFilterID,
    title: String,
    subtitle: String? = nil,
    attributedTitle: AttributedString? = nil,
    attributedSubtitle: AttributedString? = nil,
    isSelected: Bool = false,
    isEnabled: Bool = true
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.attributedTitle = attributedTitle
    self.attributedSubtitle = attributedSubtitle
    self.isSelected = isSelected
    self.isEnabled = isEnabled
  }
}

/// A titled group of options inside a panel.
public struct FKFilterSection: Hashable, Sendable {
  public let id: FKFilterID
  public var title: String?
  public var selectionMode: FKFilterSelectionMode
  /// When `true`, two-column list/grid panels hide that section’s option rows until the user expands it from the section header (when ``FKFilterTwoColumnRightSectionHeaderBehavior/togglesSectionCollapse`` is configured).
  public var isCollapsed: Bool
  public var items: [FKFilterOptionItem]

  public init(
    id: FKFilterID,
    title: String? = nil,
    selectionMode: FKFilterSelectionMode,
    items: [FKFilterOptionItem],
    isCollapsed: Bool = false
  ) {
    self.id = id
    self.title = title
    self.selectionMode = selectionMode
    self.items = items
    self.isCollapsed = isCollapsed
  }
}

/// Left column categories and right-hand sections keyed by category id.
public struct FKFilterTwoColumnModel: Hashable, Sendable {
  public struct Category: Hashable, Sendable {
    public let id: FKFilterID
    public var title: String
    public var isSelected: Bool

    public init(id: FKFilterID, title: String, isSelected: Bool = false) {
      self.id = id
      self.title = title
      self.isSelected = isSelected
    }
  }

  public var categories: [Category]
  public var sectionsByCategoryID: [FKFilterID: [FKFilterSection]]

  public init(categories: [Category], sectionsByCategoryID: [FKFilterID: [FKFilterSection]]) {
    self.categories = categories
    self.sectionsByCategoryID = sectionsByCategoryID
  }
}

