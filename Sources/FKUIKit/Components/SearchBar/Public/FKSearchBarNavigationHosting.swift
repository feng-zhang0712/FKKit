import UIKit

/// Helpers for embedding ``FKSearchBar`` in navigation chrome.
public enum FKSearchBarNavigationHosting {
  /// Installs `searchBar` as `navigationItem.titleView` and optionally sets its placeholder.
  ///
  /// Constrain width in the host layout when needed, for example:
  /// `searchBar.widthAnchor.constraint(lessThanOrEqualTo: navigationBar.widthAnchor, multiplier: 0.95)`.
  @MainActor
  public static func install(
    _ searchBar: FKSearchBar,
    in navigationItem: UINavigationItem,
    placeholder: String? = nil
  ) {
    if let placeholder {
      searchBar.placeholder = placeholder
    }
    navigationItem.titleView = searchBar
    let maxWidth = hostingWidth(for: searchBar) * 0.95
    let fitSize = searchBar.sizeThatFits(
      CGSize(width: maxWidth, height: UIView.layoutFittingCompressedSize.height)
    )
    searchBar.frame = CGRect(origin: .zero, size: fitSize)
  }

  private static func hostingWidth(for searchBar: FKSearchBar) -> CGFloat {
    if let width = searchBar.window?.windowScene?.screen.bounds.width {
      return width
    }
    // Assigned as titleView before the bar is in a window — fall back to the main screen.
    return UIScreen.main.bounds.width
  }
}
