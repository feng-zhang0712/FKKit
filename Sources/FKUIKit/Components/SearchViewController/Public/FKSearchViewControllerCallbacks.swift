import Foundation

/// Closure-based handlers for ``FKSearchViewController``; take precedence over ``FKSearchViewControllerDelegate``.
public struct FKSearchViewControllerCallbacks {
  public var onPresentationStateChanged: (@MainActor (FKSearchPresentationState) -> Void)?
  public var onResultSelected: (@MainActor (FKListItemID) -> Void)?
  /// When set, can return ``FKSearchQueryDispatch/handledByHost`` to suppress built-in results updates.
  public var onSearchQueryDispatch: (@MainActor (String, FKSearchViewController) -> FKSearchQueryDispatch)?
  /// Fired when dispatch resolves to ``FKSearchQueryDispatch/handledByHost`` or ``FKSearchResultsPresentationMode/hostHandled``.
  public var onHostSearchRequested: (@MainActor (String, FKSearchViewController) -> Void)?

  public init(
    onPresentationStateChanged: (@MainActor (FKSearchPresentationState) -> Void)? = nil,
    onResultSelected: (@MainActor (FKListItemID) -> Void)? = nil,
    onSearchQueryDispatch: (@MainActor (String, FKSearchViewController) -> FKSearchQueryDispatch)? = nil,
    onHostSearchRequested: (@MainActor (String, FKSearchViewController) -> Void)? = nil
  ) {
    self.onPresentationStateChanged = onPresentationStateChanged
    self.onResultSelected = onResultSelected
    self.onSearchQueryDispatch = onSearchQueryDispatch
    self.onHostSearchRequested = onHostSearchRequested
  }
}
