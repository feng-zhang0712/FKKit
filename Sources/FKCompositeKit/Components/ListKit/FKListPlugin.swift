import FKUIKit
import UIKit

/// Composable list coordinator: composes ``FKPageManager``, ``FKListStateManager``, FKRefresh,
/// optional skeleton + empty/error overlays, **without** subclassing ``UIViewController``.
///
/// ## Responsibilities
/// - Wires ``UIScrollView`` pull-to-refresh / load-more to ``FKPageManager`` cursors.
/// - Mirrors paging outcomes into ``FKListStateManager`` (skeleton / empty / error / content).
/// - Ends header & footer animations via ``FKListScrollViewRefreshDriver``.
/// - Keeps the host view controller and scroll view as **weak** references to avoid retain cycles.
///
/// ## Typical wiring
/// 1. `let plugin = FKListPlugin(configuration: …)`
/// 2. Assign `onRefresh` / `onLoadMore`, optionally `currentTotalItemCount`.
/// 3. `plugin.attach(scrollView: tableView, emptyStateHost: view, skeletonHost: container, hostViewController: self)`
/// 4. `plugin.startInitialLoad()` from `viewDidAppear` (once) or your own trigger.
/// 5. After each network completes: update your data source, reload the list, then ``handleSuccess(fetchedThisBatchCount:totalItemCountAfterMerge:animated:)``.
@MainActor
public final class FKListPlugin {

  public private(set) var configuration: FKListConfiguration

  /// Latest list chrome state (skeleton / overlays / content).
  public var listState: FKListState { listStateManager.state }

  public private(set) weak var scrollView: UIScrollView?
  public private(set) weak var hostViewController: UIViewController?

  public private(set) var pageManager: FKPageManager
  public private(set) var listStateManager: FKListStateManager

  /// First page, pull-to-refresh, or anything that maps to ``FKPageManager/beginInitialLoad`` / ``FKPageManager/beginRefresh``.
  public var onRefresh: ((_ parameters: FKPageRequestParameters) -> Void)?
  /// Pagination slice after a successful first page.
  public var onLoadMore: ((_ parameters: FKPageRequestParameters) -> Void)?

  public var onStateChange: ((_ previous: FKListState, _ new: FKListState) -> Void)?
  public var onAnyLoadFinished: (() -> Void)?
  public var onNoMoreData: (() -> Void)?
  /// Primary CTA on empty / hard-error overlays (maps to ``FKListStateManager/onOverlayPrimaryAction``).
  public var onEmptyOrErrorOverlayPrimaryAction: FKVoidHandler?

  /// Current rendered row count; used when ``FKListConfiguration/tracksItemCountForRefreshFailureUX`` is enabled.
  public var currentTotalItemCount: () -> Int = { 0 }

  private weak var emptyStateHost: UIView?
  private var refreshDriver: FKListScrollViewRefreshDriver?
  private var itemCountBeforeRefreshOrInitial: Int = 0
  private var hasSkeletonDriver = false
  private var isAttached = false

  public init(configuration: FKListConfiguration = FKListConfiguration()) {
    self.configuration = configuration
    self.pageManager = FKPageManager(configuration: configuration.pagination)
    self.listStateManager = FKListStateManager(
      drivers: FKListPresentationDrivers(),
      configuration: configuration.resolvedListStateManagerConfiguration()
    )
    installPageManagerBridge()
    wireEventForwarding()
  }

  // MARK: Attach

  /// Binds a scroll view (``UITableView`` / ``UICollectionView`` / plain ``UIScrollView``) to the plugin.
  @discardableResult
  public func attach(
    scrollView: UIScrollView,
    emptyStateHost: UIView,
    skeletonHost: (any FKListSkeletonDriving)? = nil,
    hostViewController: UIViewController? = nil
  ) -> Self {
    detach()
    self.scrollView = scrollView
    self.emptyStateHost = emptyStateHost
    self.hostViewController = hostViewController
    self.hasSkeletonDriver = (skeletonHost != nil) && configuration.enablesSkeletonOnInitialLoad

    let driver = FKListScrollViewRefreshDriver(scrollView: scrollView)
    refreshDriver = driver

    listStateManager.drivers = FKListPresentationDrivers(
      emptyStateHost: emptyStateHost,
      skeleton: skeletonHost,
      primarySurface: scrollView,
      refresh: driver
    )

    recomputeInitialLoadingPresentation()
    pageManager.configuration = configuration.pagination
    pageManager.hasMoreEvaluator = configuration.hasMoreEvaluator

    installPageManagerBridge()
    wireEventForwarding()

    if configuration.enablesPullToRefresh {
      scrollView.fk_addPullToRefresh(configuration: configuration.pullToRefreshConfiguration) { [weak self] in
        self?.performPullToRefreshPipeline()
      }
    }
    if configuration.enablesLoadMore {
      scrollView.fk_addLoadMore(configuration: configuration.loadMoreConfiguration) { [weak self] in
        self?.performLoadMorePipeline()
      }
    }

    isAttached = true
    return self
  }

  /// Removes refresh controls and breaks coordinator bridges; safe to call multiple times.
  public func detach() {
    scrollView?.fk_removePullToRefresh()
    scrollView?.fk_removeLoadMore()

    pageManager.onAnyLoadFinished = nil
    pageManager.onNoMoreData = nil
    pageManager.listStateManager = nil
    pageManager.automaticallyUpdatesListState = false

    listStateManager.onStateChange = nil
    listStateManager.onOverlayPrimaryAction = nil
    listStateManager.drivers = FKListPresentationDrivers()

    refreshDriver = nil
    scrollView = nil
    emptyStateHost = nil
    hostViewController = nil
    isAttached = false
  }

  /// Updates feature flags / pagination without re-creating the plugin. Call after mutating ``configuration``.
  public func applyConfiguration(_ newConfiguration: FKListConfiguration) {
    configuration = newConfiguration
    listStateManager.configuration = newConfiguration.resolvedListStateManagerConfiguration()
    pageManager.configuration = newConfiguration.pagination
    pageManager.hasMoreEvaluator = newConfiguration.hasMoreEvaluator
    recomputeInitialLoadingPresentation()

    scrollView?.fk_pullToRefresh?.isEnabled = newConfiguration.enablesPullToRefresh
    scrollView?.fk_loadMore?.isEnabled = newConfiguration.enablesLoadMore
  }

  // MARK: Lifecycle helpers

  /// Kicks off ``FKPageManager/beginInitialLoad`` and forwards parameters through ``onRefresh``.
  public func startInitialLoad() {
    guard isAttached else { return }
    captureItemCountBaselineForRefresh()
    guard let params = pageManager.beginInitialLoad() else { return }
    onRefresh?(params)
  }

  // MARK: Completion API

  /// Records a successful batch. Uses ``FKPageManager/loadPhase`` to choose ``completeFirstPage`` vs ``completeLoadMore``.
  ///
  /// - Parameters:
  ///   - fetchedThisBatchCount: Number of rows returned in this response (after any client-side filtering).
  ///   - totalItemCountAfterMerge: Pass when your UI model count diverges from the batch count (e.g. merged cache).
  public func handleSuccess(
    fetchedThisBatchCount: Int,
    totalItemCountAfterMerge: Int? = nil,
    animated: Bool = true
  ) {
    if Thread.isMainThread {
      handleSuccessOnMain(fetchedThisBatchCount: fetchedThisBatchCount, totalItemCountAfterMerge: totalItemCountAfterMerge, animated: animated)
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.handleSuccessOnMain(
          fetchedThisBatchCount: fetchedThisBatchCount,
          totalItemCountAfterMerge: totalItemCountAfterMerge,
          animated: animated
        )
      }
    }
  }

  /// Records a failed batch, rolls back cursors for load-more, and maps errors into list overlays.
  public func handleError(_ error: Error, listError: FKListDisplayedError? = nil, animated: Bool = true) {
    if error is CancellationError {
      abandonInFlightRequest()
      return
    }
    if Thread.isMainThread {
      handleErrorOnMain(error, listError: listError, animated: animated)
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.handleErrorOnMain(error, listError: listError, animated: animated)
      }
    }
  }

  /// Drops the in-flight guard without mutating cursors (e.g. cooperative cancellation).
  public func abandonInFlightRequest() {
    if Thread.isMainThread {
      pageManager.abandonInFlightRequest()
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.pageManager.abandonInFlightRequest()
      }
    }
  }

  /// Resets paging + optional idle presentation.
  public func resetListPresentation(animated: Bool = true) {
    if Thread.isMainThread {
      pageManager.resetEverything(animated: animated)
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.pageManager.resetEverything(animated: animated)
      }
    }
  }

  // MARK: - Private — wiring

  private func installPageManagerBridge() {
    pageManager.listStateManager = listStateManager
    pageManager.automaticallyUpdatesListState = true
    pageManager.hasMoreEvaluator = configuration.hasMoreEvaluator
    recomputeInitialLoadingPresentation()
    pageManager.onAnyLoadFinished = { [weak self] in
      self?.onAnyLoadFinished?()
    }
    pageManager.onNoMoreData = { [weak self] in
      self?.onNoMoreData?()
    }
  }

  private func wireEventForwarding() {
    listStateManager.onStateChange = { [weak self] previous, newState in
      self?.onStateChange?(previous, newState)
    }
    listStateManager.onOverlayPrimaryAction = { [weak self] in
      self?.onEmptyOrErrorOverlayPrimaryAction?()
    }
  }

  private func recomputeInitialLoadingPresentation() {
    let useSkeleton = configuration.enablesSkeletonOnInitialLoad && hasSkeletonDriver
    pageManager.initialLoadListPresentation = useSkeleton ? .initial : .silent
  }

  // MARK: - Private — refresh / load more pipelines

  private func captureItemCountBaselineForRefresh() {
    if configuration.tracksItemCountForRefreshFailureUX {
      itemCountBeforeRefreshOrInitial = max(0, currentTotalItemCount())
    } else {
      itemCountBeforeRefreshOrInitial = 0
    }
  }

  private func performPullToRefreshPipeline() {
    guard let scrollView else {
      return
    }
    captureItemCountBaselineForRefresh()
    guard let params = pageManager.beginRefresh() else {
      scrollView.fk_pullToRefresh?.endRefreshing()
      return
    }
    onRefresh?(params)
  }

  private func performLoadMorePipeline() {
    guard let scrollView else { return }
    guard let params = pageManager.beginLoadMore() else {
      scrollView.fk_loadMore?.endRefreshing()
      return
    }
    onLoadMore?(params)
  }

  // MARK: - Private — completions

  private func handleSuccessOnMain(fetchedThisBatchCount: Int, totalItemCountAfterMerge: Int?, animated: Bool) {
    let fetched = max(0, fetchedThisBatchCount)
    switch pageManager.loadPhase {
    case .loadingFirstPage, .refreshing:
      pageManager.completeFirstPage(
        fetchedCount: fetched,
        totalItemCountAfterMerge: totalItemCountAfterMerge,
        error: nil,
        animated: animated
      )
    case .loadingMore:
      pageManager.completeLoadMore(
        fetchedCount: fetched,
        totalItemCountAfterMerge: totalItemCountAfterMerge,
        error: nil,
        animated: animated
      )
    default:
      break
    }
  }

  private func handleErrorOnMain(_ error: Error, listError: FKListDisplayedError?, animated: Bool) {
    let mapped = listError ?? FKListDisplayedError.resolve(from: error)
    switch pageManager.loadPhase {
    case .loadingFirstPage, .refreshing:
      let before: Int? = configuration.tracksItemCountForRefreshFailureUX ? itemCountBeforeRefreshOrInitial : nil
      pageManager.completeFirstPage(
        fetchedCount: 0,
        error: error,
        listError: mapped,
        itemCountBeforeRefresh: before,
        animated: animated
      )
    case .loadingMore:
      pageManager.completeLoadMore(
        fetchedCount: 0,
        totalItemCountAfterMerge: currentTotalItemCount(),
        error: error,
        listError: mapped,
        animated: animated
      )
    default:
      break
    }
  }
}
