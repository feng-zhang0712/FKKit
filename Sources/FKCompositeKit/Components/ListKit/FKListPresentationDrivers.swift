import FKUIKit
import UIKit

// MARK: - Skeleton

/// Drives skeleton presentation for ``FKListStateManager`` (e.g. ``FKSkeletonContainerView``).
@MainActor
public protocol FKListSkeletonDriving: AnyObject {
  func fk_list_setSkeletonActive(_ active: Bool, animated: Bool)
}

extension FKSkeletonContainerView: FKListSkeletonDriving {
  public func fk_list_setSkeletonActive(_ active: Bool, animated: Bool) {
    if active {
      showSkeleton(animated: animated)
    } else {
      hideSkeleton(animated: animated)
    }
  }
}

// MARK: - Primary list surface

/// Shows or hides the main list container (table, collection, stack, etc.).
@MainActor
public protocol FKListPrimarySurfaceDriving: AnyObject {
  func fk_list_setPrimarySurfaceHidden(_ hidden: Bool, animated: Bool)
}

extension UIView: FKListPrimarySurfaceDriving {
  public func fk_list_setPrimarySurfaceHidden(_ hidden: Bool, animated: Bool) {
    let apply = {
      self.isHidden = hidden
      self.alpha = hidden ? 0 : 1
      self.isUserInteractionEnabled = !hidden
    }
    if animated {
      UIView.transition(with: self, duration: 0.2, options: [.beginFromCurrentState, .allowUserInteraction], animations: apply)
    } else {
      apply()
    }
  }
}

// MARK: - Empty / error overlay

/// Hosts ``FKEmptyState`` overlays (typically a `UIViewController.view` or the scroll view itself).
@MainActor
public protocol FKListEmptyStateDriving: AnyObject {
  func fk_list_applyEmptyState(_ model: FKEmptyStateConfiguration, animated: Bool, actionHandler: ((FKEmptyStateAction) -> Void)?)
  func fk_list_hideEmptyState(animated: Bool)
}

extension UIView: FKListEmptyStateDriving {
  public func fk_list_applyEmptyState(_ model: FKEmptyStateConfiguration, animated: Bool, actionHandler: ((FKEmptyStateAction) -> Void)?) {
    fk_applyEmptyState(model, animated: animated, actionHandler: actionHandler)
  }

  public func fk_list_hideEmptyState(animated: Bool) {
    fk_hideEmptyState(animated: animated)
  }
}

// MARK: - Refresh

/// Finishes header/footer refresh work without hard-coding ``FKRefreshControl`` inside ``FKListStateManager``.
@MainActor
public protocol FKListRefreshDriving: AnyObject {
  func fk_list_endPullToRefreshSuccess()
  func fk_list_endPullToRefreshEmptyList()
  func fk_list_endPullToRefreshFailure()
  func fk_list_finishLoadMoreSuccess(hasMorePages: Bool)
  func fk_list_finishLoadMoreFailure()
}

/// Bridges ``UIScrollView`` FKRefresh attachments to ``FKListRefreshDriving``.
@MainActor
public final class FKListScrollViewRefreshDriver: FKListRefreshDriving {

  public weak var scrollView: UIScrollView?

  public init(scrollView: UIScrollView) {
    self.scrollView = scrollView
  }

  public func fk_list_endPullToRefreshSuccess() {
    scrollView?.fk_pullToRefresh?.endRefreshing()
  }

  public func fk_list_endPullToRefreshEmptyList() {
    scrollView?.fk_pullToRefresh?.endRefreshingWithEmptyList()
  }

  public func fk_list_endPullToRefreshFailure() {
    scrollView?.fk_pullToRefresh?.endRefreshingWithError(nil)
  }

  public func fk_list_finishLoadMoreSuccess(hasMorePages: Bool) {
    guard let footer = scrollView?.fk_loadMore else { return }
    if hasMorePages {
      footer.endLoadingMore()
    } else {
      footer.endRefreshingWithNoMoreData()
    }
  }

  public func fk_list_finishLoadMoreFailure() {
    scrollView?.fk_loadMore?.endRefreshingWithError(nil)
  }
}

// MARK: - Driver bundle

/// Weak references to optional UI collaborators; pass only the pieces your screen supports.
@MainActor
public struct FKListPresentationDrivers {
  public weak var emptyStateHost: (any FKListEmptyStateDriving)?
  public weak var skeleton: (any FKListSkeletonDriving)?
  public weak var primarySurface: (any FKListPrimarySurfaceDriving)?
  public weak var refresh: (any FKListRefreshDriving)?

  public init(
    emptyStateHost: (any FKListEmptyStateDriving)? = nil,
    skeleton: (any FKListSkeletonDriving)? = nil,
    primarySurface: (any FKListPrimarySurfaceDriving)? = nil,
    refresh: (any FKListRefreshDriving)? = nil
  ) {
    self.emptyStateHost = emptyStateHost
    self.skeleton = skeleton
    self.primarySurface = primarySurface
    self.refresh = refresh
  }
}
