import UIKit

/// Maps ``FKListPresentationState`` to skeleton, empty, and table visibility.
@MainActor
final class FKListPresentationCoordinator {
  func emptyConfiguration(
    for configuration: FKListConfiguration,
    scenario: FKEmptyStateScenario
  ) -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(scenario)
    model.phase = .empty
    model.presentation.transition = .none
    if let title = configuration.empty.overridesTitle {
      model.content.title = title
    }
    if let message = configuration.empty.overridesMessage {
      model.content.description = message
    }
    return model
  }

  func errorConfiguration(
    for configuration: FKListConfiguration,
    presentation: FKListErrorPresentation
  ) -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(configuration.error.scenario)
    model.phase = .error
    model.presentation.transition = .none
    model.content.title = configuration.error.overridesTitle ?? presentation.title
    if let message = configuration.error.overridesMessage ?? presentation.message {
      model.content.description = message
    }
    if let actionTitle = configuration.error.overridesPrimaryActionTitle {
      model = model.withPrimaryAction(actionTitle, id: "retry")
    }
    return model
  }

  func showSkeleton(on tableView: UITableView, policy: FKListSkeletonPolicy, overlayHost: UIView) {
    switch policy {
    case .visibleCells:
      if tableView.visibleCells.isEmpty {
        overlayHost.fk_showSkeleton(over: tableView, animated: true)
      } else {
        tableView.fk_showAutoSkeletonOnVisibleCells(animated: true)
      }
    case .fullOverlay:
      overlayHost.fk_showSkeleton(over: tableView, animated: true)
    case .presetRows:
      overlayHost.fk_showSkeleton(over: tableView, animated: true)
    }
  }

  func hideSkeleton(
    on tableView: UITableView,
    policy: FKListSkeletonPolicy,
    overlayHost: UIView,
    completion: (() -> Void)? = nil
  ) {
    switch policy {
    case .visibleCells:
      // Initial load uses a scroll-view overlay when no cells are visible yet; after the
      // snapshot applies, visible cells may use auto placeholders instead. Hide both paths.
      overlayHost.fk_hideSkeleton(animated: true) {
        tableView.fk_hideAutoSkeletonOnVisibleCells(animated: true, completion: completion)
      }
    case .fullOverlay, .presetRows:
      overlayHost.fk_hideSkeleton(animated: true, completion: completion)
    }
  }

  func showSkeleton(on collectionView: UICollectionView, policy: FKListSkeletonPolicy, overlayHost: UIView) {
    switch policy {
    case .visibleCells:
      if collectionView.visibleCells.isEmpty {
        overlayHost.fk_showSkeleton(over: collectionView, animated: true)
      } else {
        collectionView.fk_showAutoSkeletonOnVisibleCells(animated: true)
      }
    case .fullOverlay:
      overlayHost.fk_showSkeleton(over: collectionView, animated: true)
    case .presetRows:
      overlayHost.fk_showSkeleton(over: collectionView, animated: true)
    }
  }

  func hideSkeleton(
    on collectionView: UICollectionView,
    policy: FKListSkeletonPolicy,
    overlayHost: UIView,
    completion: (() -> Void)? = nil
  ) {
    switch policy {
    case .visibleCells:
      overlayHost.fk_hideSkeleton(animated: true) {
        collectionView.fk_hideAutoSkeletonOnVisibleCells(animated: true, completion: completion)
      }
    case .fullOverlay, .presetRows:
      overlayHost.fk_hideSkeleton(animated: true, completion: completion)
    }
  }

  func applyEmptyState(
    on scrollView: UIScrollView,
    configuration: FKEmptyStateConfiguration,
    policy: FKListEmptyPresentationPolicy,
    hostView: UIView,
    hidesList: Bool,
    listView: UIView,
    animatesPresentation: Bool,
    retry: @escaping () -> Void
  ) {
    switch policy {
    case .overlayScrollView:
      listView.isHidden = false
      scrollView.fk_applyEmptyState(configuration, animated: animatesPresentation) { action in
        if action.kind == .primary {
          retry()
        }
      }
    case .replaceContent:
      listView.isHidden = hidesList
      hostView.fk_applyEmptyState(configuration, animated: animatesPresentation) { action in
        if action.kind == .primary {
          retry()
        }
      }
    case .inlineZeroRows:
      listView.isHidden = false
      scrollView.fk_applyEmptyState(configuration, animated: animatesPresentation) { action in
        if action.kind == .primary {
          retry()
        }
      }
    }
  }

  func hideEmptyState(
    on scrollView: UIScrollView,
    hostView: UIView,
    policy: FKListEmptyPresentationPolicy,
    animatesPresentation: Bool
  ) {
    removeEmptyState(on: scrollView, animated: animatesPresentation)
    if policy == .replaceContent {
      removeEmptyState(on: hostView, animated: animatesPresentation)
    }
  }

  /// Hides the empty overlay while pull-to-refresh runs so ``FKRefreshControl`` stays visible.
  func hideEmptyStateForRefreshIfNeeded(
    on scrollView: UIScrollView,
    hostView: UIView,
    policy: FKListEmptyPresentationPolicy
  ) {
    hideEmptyState(
      on: scrollView,
      hostView: hostView,
      policy: policy,
      animatesPresentation: false
    )
  }

  private func removeEmptyState(on host: UIView, animated: Bool) {
    host.fk_removeEmptyState(animated: animated)
  }

  func announceRefreshCompletionIfNeeded(configuration: FKListConfiguration, succeeded: Bool) {
    guard configuration.accessibility.announcesRefreshCompletion else { return }
    let message = succeeded ? "Refresh completed" : "Refresh failed"
    UIAccessibility.post(notification: .announcement, argument: message)
  }
}
