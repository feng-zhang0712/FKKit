import ObjectiveC.runtime
import UIKit

// MARK: - Associated objects

enum FKEmptyStateHostKeys {
  nonisolated(unsafe) static var view: UInt8 = 0
  nonisolated(unsafe) static var configuration: UInt8 = 0
}

/// Box so the last-applied ``FKEmptyStateConfiguration`` can live in associated objects.
final class FKEmptyStateConfigurationBox {
  let configuration: FKEmptyStateConfiguration
  init(_ configuration: FKEmptyStateConfiguration) { self.configuration = configuration }
}

// MARK: - Scroll / refresh helpers

/// Returns `true` while pull-to-refresh (or `UIRefreshControl`) is actively pulling or refreshing.
@MainActor
func fk_emptyStateIsPullToRefreshActive(on scrollView: UIScrollView) -> Bool {
  if scrollView.refreshControl?.isRefreshing == true { return true }
  guard let pull = scrollView.fk_pullToRefresh else { return false }
  switch pull.state {
  case .refreshing, .loadingMore, .triggered, .readyToRefresh, .pulling:
    return true
  case .idle, .finished, .listEmpty, .failed, .noMoreData:
    return false
  }
}

/// Returns `true` when a loading overlay should be suppressed because pull-to-refresh is active.
@MainActor
func fk_emptyStateShouldSkipLoadingBecauseOfRefresh(host: UIView, configuration: FKEmptyStateConfiguration) -> Bool {
  guard let scroll = host as? UIScrollView else { return false }
  guard configuration.phase == .loading, configuration.presentation.loadingBehavior.skipsWhileRefreshing else { return false }
  return fk_emptyStateIsPullToRefreshActive(on: scroll)
}

/// Keeps ``FKRefreshControl`` header/footer above an empty-state overlay on the same scroll view.
@MainActor
func fk_emptyStateBringRefreshControlsToFront(on scrollView: UIScrollView) {
  scrollView.fk_pullToRefresh.map { scrollView.bringSubviewToFront($0) }
  scrollView.fk_loadMore.map { scrollView.bringSubviewToFront($0) }
}

/// Applies ``FKEmptyStatePresentationConfiguration/keepScrollEnabled`` when the host is a `UIScrollView`.
@MainActor
func fk_emptyStateApplyScrollInteraction(host: UIView, configuration: FKEmptyStateConfiguration) {
  guard let scroll = host as? UIScrollView else { return }
  scroll.isScrollEnabled = configuration.presentation.keepScrollEnabled
}

/// Clears associated-object storage for an empty-state host after ``UIView/fk_removeEmptyState(animated:)``.
@MainActor
func fk_emptyStateClearHostStorage(on host: UIView) {
  objc_setAssociatedObject(host, &FKEmptyStateHostKeys.view, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  objc_setAssociatedObject(host, &FKEmptyStateHostKeys.configuration, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}
