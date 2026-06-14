import Foundation

/// Optional delegate for ``FKSearchViewController`` lifecycle and interactions.
@MainActor
public protocol FKSearchViewControllerDelegate: AnyObject {
  func searchViewController(_ viewController: FKSearchViewController, stateChanged state: FKSearchPresentationState)
  func searchViewController(_ viewController: FKSearchViewController, didSelect item: FKListItemID)
  func searchViewController(_ viewController: FKSearchViewController, searchQueryDispatchFor query: String) -> FKSearchQueryDispatch
  func searchViewController(_ viewController: FKSearchViewController, hostSearchRequested query: String)
}

public extension FKSearchViewControllerDelegate {
  func searchViewController(_ viewController: FKSearchViewController, stateChanged state: FKSearchPresentationState) {}
  func searchViewController(_ viewController: FKSearchViewController, didSelect item: FKListItemID) {}
  func searchViewController(
    _ viewController: FKSearchViewController,
    searchQueryDispatchFor query: String
  ) -> FKSearchQueryDispatch {
    .performBuiltIn
  }
  func searchViewController(_ viewController: FKSearchViewController, hostSearchRequested query: String) {}
}
