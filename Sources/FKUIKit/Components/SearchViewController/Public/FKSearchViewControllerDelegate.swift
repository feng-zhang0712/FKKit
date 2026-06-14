import Foundation

/// Optional delegate for ``FKSearchViewController`` lifecycle and interactions.
@MainActor
public protocol FKSearchViewControllerDelegate: AnyObject {
  func searchViewController(_ viewController: FKSearchViewController, stateChanged state: FKSearchPresentationState)
  func searchViewController(_ viewController: FKSearchViewController, didSelect item: FKListItemID)
}

public extension FKSearchViewControllerDelegate {
  func searchViewController(_ viewController: FKSearchViewController, stateChanged state: FKSearchPresentationState) {}
  func searchViewController(_ viewController: FKSearchViewController, didSelect item: FKListItemID) {}
}
