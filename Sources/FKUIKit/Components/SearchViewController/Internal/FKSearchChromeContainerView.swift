import UIKit

/// Hosts ``FKSearchBar`` for sticky-header placement with standard content insets.
@MainActor
final class FKSearchChromeContainerView: UIView {
  let searchBar: FKSearchBar

  init(searchBar: FKSearchBar, contentInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)) {
    self.searchBar = searchBar
    super.init(frame: .zero)
    backgroundColor = .systemBackground
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    addSubview(searchBar)
    NSLayoutConstraint.activate([
      searchBar.topAnchor.constraint(equalTo: topAnchor, constant: contentInsets.top),
      searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInsets.left),
      searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInsets.right),
      searchBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInsets.bottom),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }
}
