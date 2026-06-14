import Foundation

/// Closure-based handlers for ``FKSearchViewController``; take precedence over ``FKSearchViewControllerDelegate``.
public struct FKSearchViewControllerCallbacks {
  public var onPresentationStateChanged: (@MainActor (FKSearchPresentationState) -> Void)?
  public var onResultSelected: (@MainActor (FKListItemID) -> Void)?

  public init(
    onPresentationStateChanged: (@MainActor (FKSearchPresentationState) -> Void)? = nil,
    onResultSelected: (@MainActor (FKListItemID) -> Void)? = nil
  ) {
    self.onPresentationStateChanged = onPresentationStateChanged
    self.onResultSelected = onResultSelected
  }
}
