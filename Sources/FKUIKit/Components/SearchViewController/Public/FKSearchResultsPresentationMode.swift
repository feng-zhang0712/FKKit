import Foundation

/// How ``FKSearchViewController`` presents search results below the search chrome.
public enum FKSearchResultsPresentationMode: Sendable, Equatable {
  /// Default — ``FKSearchViewController/makeListViewController()``; idle and results share one embedded list.
  case embeddedList
  /// Host supplies ``FKSearchViewController/makeResultsViewController()``; may conform to ``FKSearchResultsDisplaying``.
  case customViewController
  /// Built-in results updates are suppressed; the host navigates or renders results externally.
  case hostHandled
}
