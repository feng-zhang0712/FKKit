import UIKit

/// Cancel, animation, and idle behavior for ``FKSearchViewController``.
public struct FKSearchBehaviorConfiguration: Sendable, Equatable {
  /// When cancel clears query, restore local baseline or remote idle snapshot.
  public var cancelRestoresBaseline: Bool
  /// Cancel in-flight search when the view controller disappears.
  public var cancelsOnDisappear: Bool
  public var animatesSnapshotChanges: Bool
  /// When `true`, remote mode shows ``FKSearchViewController/remoteIdleSnapshot`` for empty query.
  public var showsResultsOnEmptyQuery: Bool
  /// Auto-focus search field on first appearance.
  public var focusesSearchOnAppear: Bool

  public init(
    cancelRestoresBaseline: Bool = true,
    cancelsOnDisappear: Bool = true,
    animatesSnapshotChanges: Bool = true,
    showsResultsOnEmptyQuery: Bool = false,
    focusesSearchOnAppear: Bool = false
  ) {
    self.cancelRestoresBaseline = cancelRestoresBaseline
    self.cancelsOnDisappear = cancelsOnDisappear
    self.animatesSnapshotChanges = animatesSnapshotChanges
    self.showsResultsOnEmptyQuery = showsResultsOnEmptyQuery
    self.focusesSearchOnAppear = focusesSearchOnAppear
  }
}

/// Loading presentation during remote queries in ``FKSearchViewController``.
public struct FKSearchViewControllerLoadingConfiguration: Sendable, Equatable {
  public var useSkeleton: Bool
  /// Reserved for future row-placeholder skeleton APIs; v1 overlay mode ignores this value.
  public var skeletonRowCount: Int
  /// Drives ``FKSearchBar/setLoading(_:animated:)`` during remote queries.
  public var searchBarLoading: Bool

  public init(
    useSkeleton: Bool = false,
    skeletonRowCount: Int = 8,
    searchBarLoading: Bool = true
  ) {
    self.useSkeleton = useSkeleton
    self.skeletonRowCount = max(1, skeletonRowCount)
    self.searchBarLoading = searchBarLoading
  }
}

/// Empty-state semantics for search-specific scenarios.
public struct FKSearchEmptyConfiguration: Sendable, Equatable {
  /// Scenario when a non-empty query yields zero rows.
  public var searchNoResultsScenario: FKEmptyStateScenario
  /// Optional idle scenario when remote query is empty; `nil` hides empty overlay.
  public var remoteIdleScenario: FKEmptyStateScenario?
  public var overridesTitle: String?
  public var overridesMessage: String?

  public init(
    searchNoResultsScenario: FKEmptyStateScenario = .noSearchResult,
    remoteIdleScenario: FKEmptyStateScenario? = nil,
    overridesTitle: String? = nil,
    overridesMessage: String? = nil
  ) {
    self.searchNoResultsScenario = searchNoResultsScenario
    self.remoteIdleScenario = remoteIdleScenario
    self.overridesTitle = overridesTitle
    self.overridesMessage = overridesMessage
  }
}

/// Root configuration for ``FKSearchViewController``.
public struct FKSearchViewControllerConfiguration: Sendable, Equatable {
  public var mode: FKSearchMode
  public var placement: FKSearchBarPlacement
  public var searchBar: FKSearchBarConfiguration
  public var list: FKListConfiguration
  public var loading: FKSearchViewControllerLoadingConfiguration
  public var empty: FKSearchEmptyConfiguration
  public var behavior: FKSearchBehaviorConfiguration
  public var presentation: FKSearchPresentationConfiguration

  public init(
    mode: FKSearchMode = .localFilter,
    placement: FKSearchBarPlacement = .stickyHeader,
    searchBar: FKSearchBarConfiguration = FKSearchBarDefaults.inlineCard(),
    list: FKListConfiguration = FKSearchViewControllerDefaults.makeListConfiguration(),
    loading: FKSearchViewControllerLoadingConfiguration = FKSearchViewControllerLoadingConfiguration(),
    empty: FKSearchEmptyConfiguration = FKSearchEmptyConfiguration(),
    behavior: FKSearchBehaviorConfiguration = FKSearchBehaviorConfiguration(),
    presentation: FKSearchPresentationConfiguration = .unified
  ) {
    self.mode = mode
    self.placement = placement
    self.searchBar = searchBar
    self.list = list
    self.loading = loading
    self.empty = empty
    self.behavior = behavior
    self.presentation = presentation
  }
}

/// Preset factories for common search page setups.
public enum FKSearchViewControllerDefaults {
  /// Local in-memory filter with sticky header and inline search card.
  public static func localFilter(
    placement: FKSearchBarPlacement = .stickyHeader
  ) -> FKSearchViewControllerConfiguration {
    FKSearchViewControllerConfiguration(
      mode: .localFilter,
      placement: placement,
      searchBar: searchBarConfiguration(for: placement),
      list: makeListConfiguration(),
      loading: FKSearchViewControllerLoadingConfiguration(useSkeleton: false, searchBarLoading: false),
      behavior: FKSearchBehaviorConfiguration()
    )
  }

  /// Remote async search with loading chrome enabled by default.
  public static func remote(
    placement: FKSearchBarPlacement = .stickyHeader
  ) -> FKSearchViewControllerConfiguration {
    FKSearchViewControllerConfiguration(
      mode: .remote,
      placement: placement,
      searchBar: searchBarConfiguration(for: placement),
      list: makeListConfiguration(),
      loading: FKSearchViewControllerLoadingConfiguration(useSkeleton: true, searchBarLoading: true),
      behavior: FKSearchBehaviorConfiguration()
    )
  }

  /// Shared list defaults tuned for search pages.
  public static func makeListConfiguration() -> FKListConfiguration {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    config.loading.usesSkeletonForInitialLoad = false
    config.search = FKListSearchConfiguration(
      clearsSelectionOnSearch: true,
      emptyScenario: .noSearchResult
    )
    config.empty.scenario = .noSearchResult
    return config
  }

  private static func searchBarConfiguration(for placement: FKSearchBarPlacement) -> FKSearchBarConfiguration {
    switch placement {
    case .navigationBar:
      return FKSearchBarDefaults.navigationBar()
    case .stickyHeader, .tableHeader:
      return FKSearchBarDefaults.inlineCard()
    case .stickyFooter:
      return FKSearchBarDefaults.inlineCard()
    }
  }
}
