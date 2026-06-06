import ObjectiveC.runtime
import UIKit

// MARK: - UIScrollView

public extension UIScrollView {
  /// Updates the existing overlay’s content without tearing down the view.
  ///
  /// Falls back to ``fk_applyEmptyState(_:animated:actionHandler:viewTapHandler:)`` when no overlay is visible.
  /// Content transitions run only when `animated` is `true` and ``FKEmptyStatePresentationConfiguration/transition`` is not `.none`.
  func fk_updateEmptyState(_ model: FKEmptyStateConfiguration, animated: Bool = true) {
    fk_updateVisibleEmptyState(model, animated: animated)
  }

  /// When `isEmpty` is false, forces `phase = .content` before applying (hides overlay).
  ///
  /// - Parameter isEmpty: Pass your list emptiness predicate (e.g. `items.isEmpty`).
  func fk_updateEmptyStateVisibility(
    isEmpty: Bool,
    configuration: FKEmptyStateConfiguration,
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    var resolved = configuration
    if !isEmpty {
      resolved.phase = .content
    }
    fk_applyEmptyState(
      resolved,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }

  /// If `automaticallyShowsWhenContentFits` is enabled on the stored configuration, shows the empty state when `contentSize` fits in the visible area.
  ///
  /// Call from `scrollViewDidScroll` / `layoutSubviews` when using short content empty states.
  ///
  /// Edge cases:
  /// - Uses `adjustedContentInset` and bounds height; safe area and refresh controls are accounted for.
  /// - Will only run when `fk_emptyStateConfiguration.presentation.automaticallyShowsWhenContentFits == true`.
  func fk_refreshEmptyStateAutomatically(
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    fk_emptyStateAssertMainThread()
    guard var model = fk_emptyStateConfiguration, model.presentation.automaticallyShowsWhenContentFits else { return }
    let visibleHeight = bounds.height - adjustedContentInset.top - adjustedContentInset.bottom
    let shouldShow = contentSize.height <= max(0, visibleHeight)
    if shouldShow, model.phase == .content {
      model.phase = .empty
    }
    fk_updateEmptyStateVisibility(
      isEmpty: shouldShow,
      configuration: model,
      animated: true,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }

  /// Shows the overlay when `itemCount == 0`; otherwise hides it (`phase = .content`).
  ///
  /// If `itemCount == 0` and the configuration’s `phase == .content`, coerces phase to `.empty` so something visible is shown.
  ///
  /// - Note: For collection views, prefer `fk_totalItemCount()` to compute `itemCount`.
  func fk_updateEmptyState(
    itemCount: Int,
    configuration: FKEmptyStateConfiguration,
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    fk_emptyStateAssertMainThread()
    if itemCount > 0 {
      var hidden = configuration
      hidden.phase = .content
      fk_applyEmptyState(
        hidden,
        animated: animated,
        actionHandler: actionHandler,
        viewTapHandler: viewTapHandler
      )
    } else {
      var emptyModel = configuration
      if emptyModel.phase == .content {
        emptyModel.phase = .empty
      }
      fk_applyEmptyState(
        emptyModel,
        animated: animated,
        actionHandler: actionHandler,
        viewTapHandler: viewTapHandler
      )
    }
  }
}

// MARK: - UITableView

public extension UITableView {
  /// Sums `numberOfRows(inSection:)` across all sections (handy for `fk_updateEmptyState(itemCount:...)`).
  func fk_totalRowCount() -> Int {
    (0..<numberOfSections).reduce(0) { partial, section in
      partial + numberOfRows(inSection: section)
    }
  }

  /// Uses `fk_totalRowCount()` as `itemCount` for `fk_updateEmptyState(itemCount:configuration:...)`.
  func fk_updateEmptyStateForTable(
    configuration: FKEmptyStateConfiguration,
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    fk_updateEmptyState(
      itemCount: fk_totalRowCount(),
      configuration: configuration,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }
}

// MARK: - UICollectionView

public extension UICollectionView {
  /// Sums `numberOfItems(inSection:)` across all sections.
  func fk_totalItemCount() -> Int {
    (0..<numberOfSections).reduce(0) { partial, section in
      partial + numberOfItems(inSection: section)
    }
  }
}
