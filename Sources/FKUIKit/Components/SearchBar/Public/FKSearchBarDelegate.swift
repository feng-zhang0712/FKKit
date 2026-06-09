import UIKit

/// Optional delegate callbacks for ``FKSearchBar``.
///
/// Callbacks on ``FKSearchBar/callbacks`` take precedence; delegate methods fire only when the matching callback is `nil`.
@MainActor
public protocol FKSearchBarDelegate: AnyObject {
  func searchBar(_ searchBar: FKSearchBar, textDidChange text: String)
  func searchBar(_ searchBar: FKSearchBar, searchQueryDidChange query: String)
  func searchBarSearchButtonClicked(_ searchBar: FKSearchBar)
  func searchBarCancelButtonClicked(_ searchBar: FKSearchBar)
  func searchBarClearButtonClicked(_ searchBar: FKSearchBar)
  func searchBarTextDidBeginEditing(_ searchBar: FKSearchBar)
  func searchBarTextDidEndEditing(_ searchBar: FKSearchBar)
}

public extension FKSearchBarDelegate {
  func searchBar(_ searchBar: FKSearchBar, textDidChange text: String) {}
  func searchBar(_ searchBar: FKSearchBar, searchQueryDidChange query: String) {}
  func searchBarSearchButtonClicked(_ searchBar: FKSearchBar) {}
  func searchBarCancelButtonClicked(_ searchBar: FKSearchBar) {}
  func searchBarClearButtonClicked(_ searchBar: FKSearchBar) {}
  func searchBarTextDidBeginEditing(_ searchBar: FKSearchBar) {}
  func searchBarTextDidEndEditing(_ searchBar: FKSearchBar) {}
}
