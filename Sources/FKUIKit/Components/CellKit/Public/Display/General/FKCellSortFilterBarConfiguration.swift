import Foundation

/// Configuration for ``FKCellSortFilterBarCell`` (D-78).
public struct FKCellSortFilterBarConfiguration: Sendable, Equatable {
  public var sortTitle: String
  public var filterTitle: String
  public var showsSort: Bool
  public var showsFilter: Bool
  public var isEnabled: Bool

  public init(
    sortTitle: String = "Sort",
    filterTitle: String = "Filter",
    showsSort: Bool = true,
    showsFilter: Bool = true,
    isEnabled: Bool = true
  ) {
    self.sortTitle = sortTitle
    self.filterTitle = filterTitle
    self.showsSort = showsSort
    self.showsFilter = showsFilter
    self.isEnabled = isEnabled
  }
}
