import UIKit

// MARK: - Separator

/// Row separator rendering mode.
public enum FKListSeparatorMode: Sendable, Equatable {
  case system
  case fkDivider(leadingInset: CGFloat)
  case none
}

// MARK: - Row height

/// Row height policy for table lists.
public enum FKListRowHeightPolicy: Sendable, Equatable {
  case automatic
  case fixed(CGFloat)
}

// MARK: - Selection

/// Table/collection selection behavior.
public enum FKListSelectionMode: Sendable, Equatable {
  case none
  case single(deselectOnSecondTap: Bool = false)
  case multiple
}

// MARK: - Layout

/// Layout and structural table settings.
public struct FKListLayoutConfiguration: Sendable, Equatable {
  public var contentInsets: UIEdgeInsets
  public var separatorMode: FKListSeparatorMode
  public var rowHeightPolicy: FKListRowHeightPolicy
  public var sectionHeaderTopPadding: CGFloat
  public var pinsSectionHeaders: Bool
  public var emptyPresentationPolicy: FKListEmptyPresentationPolicy

  public init(
    contentInsets: UIEdgeInsets = .zero,
    separatorMode: FKListSeparatorMode = .fkDivider(leadingInset: 16),
    rowHeightPolicy: FKListRowHeightPolicy = .automatic,
    sectionHeaderTopPadding: CGFloat = 0,
    pinsSectionHeaders: Bool = true,
    emptyPresentationPolicy: FKListEmptyPresentationPolicy = .overlayScrollView
  ) {
    self.contentInsets = contentInsets
    self.separatorMode = separatorMode
    self.rowHeightPolicy = rowHeightPolicy
    self.sectionHeaderTopPadding = sectionHeaderTopPadding
    self.pinsSectionHeaders = pinsSectionHeaders
    self.emptyPresentationPolicy = emptyPresentationPolicy
  }
}

// MARK: - Appearance

/// Typography and chrome for preset cells and section headers.
public struct FKListAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var titleFont: UIFont
  public var subtitleFont: UIFont
  public var titleColor: UIColor
  public var subtitleColor: UIColor
  public var separatorColor: UIColor
  public var selectedBackgroundColor: UIColor
  public var sectionHeaderFont: UIFont
  public var sectionHeaderColor: UIColor
  public var disabledAlpha: CGFloat

  public init(
    titleFont: UIFont = .preferredFont(forTextStyle: .body),
    subtitleFont: UIFont = .preferredFont(forTextStyle: .subheadline),
    titleColor: UIColor = .label,
    subtitleColor: UIColor = .secondaryLabel,
    separatorColor: UIColor = .separator,
    selectedBackgroundColor: UIColor = .systemGray5,
    sectionHeaderFont: UIFont = .preferredFont(forTextStyle: .footnote),
    sectionHeaderColor: UIColor = .secondaryLabel,
    disabledAlpha: CGFloat = 0.4
  ) {
    self.titleFont = titleFont
    self.subtitleFont = subtitleFont
    self.titleColor = titleColor
    self.subtitleColor = subtitleColor
    self.separatorColor = separatorColor
    self.selectedBackgroundColor = selectedBackgroundColor
    self.sectionHeaderFont = sectionHeaderFont
    self.sectionHeaderColor = sectionHeaderColor
    self.disabledAlpha = disabledAlpha
  }
}

// MARK: - Refresh

/// Pull-to-refresh and load-more integration with ``FKRefresh``.
public struct FKListRefreshConfiguration: Sendable, Equatable {
  public var isPullToRefreshEnabled: Bool
  public var isLoadMoreEnabled: Bool
  public var loadMoreTriggerMode: FKLoadMoreTriggerMode
  public var loadMorePreloadOffset: CGFloat
  public var automaticallyEndsRefreshingOnAsyncCompletion: Bool
  public var resetsPaginationOnRefresh: Bool
  public var clearsSnapshotOnRefreshStart: Bool
  public var cancelsLoadMoreOnRefresh: Bool
  public var refreshFailureKeepsContent: Bool
  /// When `false`, the load-more footer stays visible even when the list does not scroll yet.
  public var autohidesLoadMoreFooterWhenNotScrollable: Bool

  public init(
    isPullToRefreshEnabled: Bool = true,
    isLoadMoreEnabled: Bool = true,
    loadMoreTriggerMode: FKLoadMoreTriggerMode = .automatic,
    loadMorePreloadOffset: CGFloat = 0,
    automaticallyEndsRefreshingOnAsyncCompletion: Bool = true,
    resetsPaginationOnRefresh: Bool = true,
    clearsSnapshotOnRefreshStart: Bool = false,
    cancelsLoadMoreOnRefresh: Bool = true,
    refreshFailureKeepsContent: Bool = true,
    autohidesLoadMoreFooterWhenNotScrollable: Bool = false
  ) {
    self.isPullToRefreshEnabled = isPullToRefreshEnabled
    self.isLoadMoreEnabled = isLoadMoreEnabled
    self.loadMoreTriggerMode = loadMoreTriggerMode
    self.loadMorePreloadOffset = max(0, loadMorePreloadOffset)
    self.automaticallyEndsRefreshingOnAsyncCompletion = automaticallyEndsRefreshingOnAsyncCompletion
    self.resetsPaginationOnRefresh = resetsPaginationOnRefresh
    self.clearsSnapshotOnRefreshStart = clearsSnapshotOnRefreshStart
    self.cancelsLoadMoreOnRefresh = cancelsLoadMoreOnRefresh
    self.refreshFailureKeepsContent = refreshFailureKeepsContent
    self.autohidesLoadMoreFooterWhenNotScrollable = autohidesLoadMoreFooterWhenNotScrollable
  }

  /// Builds a footer refresh configuration from list refresh settings.
  public func loadMoreRefreshConfiguration() -> FKRefreshConfiguration {
    var config = FKRefreshSettings.loadMore
    config.loadMoreTriggerMode = loadMoreTriggerMode
    config.loadMorePreloadOffset = loadMorePreloadOffset
    config.autohidesFooterWhenNotScrollable = autohidesLoadMoreFooterWhenNotScrollable
    return config
  }
}

// MARK: - Loading

/// Initial loading skeleton behavior.
public struct FKListLoadingConfiguration: Sendable, Equatable {
  public var usesSkeletonForInitialLoad: Bool
  public var skeletonPolicy: FKListSkeletonPolicy

  public init(
    usesSkeletonForInitialLoad: Bool = true,
    skeletonPolicy: FKListSkeletonPolicy = .visibleCells
  ) {
    self.usesSkeletonForInitialLoad = usesSkeletonForInitialLoad
    self.skeletonPolicy = skeletonPolicy
  }
}

// MARK: - Empty

/// Empty state template for zero-item snapshots.
public struct FKListEmptyConfiguration: Sendable, Equatable {
  public var scenario: FKEmptyStateScenario
  public var overridesTitle: String?
  public var overridesMessage: String?
  /// When `false`, empty overlays appear without fade or content transition (default).
  public var animatesPresentation: Bool

  public init(
    scenario: FKEmptyStateScenario = .noSearchResult,
    overridesTitle: String? = nil,
    overridesMessage: String? = nil,
    animatesPresentation: Bool = false
  ) {
    self.scenario = scenario
    self.overridesTitle = overridesTitle
    self.overridesMessage = overridesMessage
    self.animatesPresentation = animatesPresentation
  }
}

// MARK: - Error

/// Error overlay behavior on failed loads.
public struct FKListErrorConfiguration: Sendable, Equatable {
  public var preservesContentOnError: Bool
  public var scenario: FKEmptyStateScenario
  public var overridesTitle: String?
  public var overridesMessage: String?
  public var overridesPrimaryActionTitle: String?
  /// When `false`, error overlays appear without fade or content transition (default).
  public var animatesPresentation: Bool

  public init(
    preservesContentOnError: Bool = false,
    scenario: FKEmptyStateScenario = .loadFailed,
    overridesTitle: String? = nil,
    overridesMessage: String? = nil,
    overridesPrimaryActionTitle: String? = nil,
    animatesPresentation: Bool = false
  ) {
    self.preservesContentOnError = preservesContentOnError
    self.scenario = scenario
    self.overridesTitle = overridesTitle
    self.overridesMessage = overridesMessage
    self.overridesPrimaryActionTitle = overridesPrimaryActionTitle
    self.animatesPresentation = animatesPresentation
  }
}

// MARK: - Selection config

/// Selection and haptic settings.
public struct FKListSelectionConfiguration: Sendable, Equatable {
  public var mode: FKListSelectionMode
  public var preservesSelectionOnUpdates: Bool
  public var playsHapticOnSelect: Bool

  public init(
    mode: FKListSelectionMode = .single(),
    preservesSelectionOnUpdates: Bool = true,
    playsHapticOnSelect: Bool = false
  ) {
    self.mode = mode
    self.preservesSelectionOnUpdates = preservesSelectionOnUpdates
    self.playsHapticOnSelect = playsHapticOnSelect
  }
}

// MARK: - Accessibility

/// Accessibility options for list infrastructure.
public struct FKListAccessibilityConfiguration: Sendable, Equatable {
  public var announcesRefreshCompletion: Bool

  public init(announcesRefreshCompletion: Bool = false) {
    self.announcesRefreshCompletion = announcesRefreshCompletion
  }
}

// MARK: - Prefetch

/// UITableView/UICollectionView prefetch forwarding.
public struct FKListPrefetchConfiguration: Sendable, Equatable {
  public var isEnabled: Bool

  public init(isEnabled: Bool = false) {
    self.isEnabled = isEnabled
  }
}

// MARK: - Search

/// Optional search-driven list behavior.
public struct FKListSearchConfiguration: Sendable, Equatable {
  public var clearsSelectionOnSearch: Bool
  public var emptyScenario: FKEmptyStateScenario

  public init(
    clearsSelectionOnSearch: Bool = true,
    emptyScenario: FKEmptyStateScenario = .noSearchResult
  ) {
    self.clearsSelectionOnSearch = clearsSelectionOnSearch
    self.emptyScenario = emptyScenario
  }
}

// MARK: - Aggregate

/// Root configuration for ``FKDiffableTableViewController`` and ``FKDiffableCollectionViewController``.
public struct FKListConfiguration: Sendable, Equatable {
  public var layout: FKListLayoutConfiguration
  public var appearance: FKListAppearanceConfiguration
  public var refresh: FKListRefreshConfiguration
  public var loading: FKListLoadingConfiguration
  public var empty: FKListEmptyConfiguration
  public var error: FKListErrorConfiguration
  public var selection: FKListSelectionConfiguration
  public var accessibility: FKListAccessibilityConfiguration
  public var prefetch: FKListPrefetchConfiguration
  public var search: FKListSearchConfiguration?

  public init(
    layout: FKListLayoutConfiguration = FKListLayoutConfiguration(),
    appearance: FKListAppearanceConfiguration = FKListAppearanceConfiguration(),
    refresh: FKListRefreshConfiguration = FKListRefreshConfiguration(),
    loading: FKListLoadingConfiguration = FKListLoadingConfiguration(),
    empty: FKListEmptyConfiguration = FKListEmptyConfiguration(),
    error: FKListErrorConfiguration = FKListErrorConfiguration(),
    selection: FKListSelectionConfiguration = FKListSelectionConfiguration(),
    accessibility: FKListAccessibilityConfiguration = FKListAccessibilityConfiguration(),
    prefetch: FKListPrefetchConfiguration = FKListPrefetchConfiguration(),
    search: FKListSearchConfiguration? = nil
  ) {
    self.layout = layout
    self.appearance = appearance
    self.refresh = refresh
    self.loading = loading
    self.empty = empty
    self.error = error
    self.selection = selection
    self.accessibility = accessibility
    self.prefetch = prefetch
    self.search = search
  }
}

// MARK: - Defaults

/// Shared default configuration for list view controllers.
public enum FKListDefaults {
  public static var defaultConfiguration: FKListConfiguration {
    FKListConfiguration()
  }
}
