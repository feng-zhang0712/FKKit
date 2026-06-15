import Foundation

/// How idle (empty-query) body content is shown below the search chrome.
public enum FKSearchIdleContentPresentation: Sendable, Equatable {
  /// Idle content is a list snapshot on the results surface (default unified behavior).
  case listSnapshot
  /// Show ``FKSearchViewController/makeSearchContentViewController()`` when the query is empty.
  case customViewController
  /// No dedicated idle body; results surface stays hidden until a query is active.
  case none
}
