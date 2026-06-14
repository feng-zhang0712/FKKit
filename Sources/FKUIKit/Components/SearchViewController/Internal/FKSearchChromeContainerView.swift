import UIKit

/// Hosts ``FKSearchBar`` and an optional accessory for ``FKSearchBarPlacement/stickyHeader`` and ``FKSearchBarPlacement/stickyFooter``.
@MainActor
final class FKSearchChromeContainerView: UIView {
  let searchBar: FKSearchBar

  private var stackView: UIStackView?
  private let contentInsets: UIEdgeInsets

  init(
    searchBar: FKSearchBar,
    accessoryView: UIView? = nil,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
  ) {
    self.searchBar = searchBar
    self.contentInsets = contentInsets
    super.init(frame: .zero)
    backgroundColor = .systemBackground

    if let accessoryView {
      installStackLayout(accessoryView: accessoryView)
    } else {
      installDirectSearchBarLayout()
    }
  }

  func setAccessoryView(_ accessoryView: UIView?) {
    if let stackView {
      if stackView.arrangedSubviews.count > 1 {
        let existing = stackView.arrangedSubviews[1]
        stackView.removeArrangedSubview(existing)
        existing.removeFromSuperview()
      }
      guard let accessoryView else { return }
      accessoryView.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(accessoryView)
      return
    }

    guard let accessoryView else { return }
    searchBar.removeFromSuperview()
    installStackLayout(accessoryView: accessoryView)
  }

  private func installDirectSearchBarLayout() {
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    addSubview(searchBar)
    NSLayoutConstraint.activate([
      searchBar.topAnchor.constraint(equalTo: topAnchor, constant: contentInsets.top),
      searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInsets.left),
      searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInsets.right),
      searchBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInsets.bottom),
    ])
  }

  private func installStackLayout(accessoryView: UIView) {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    accessoryView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(stackView)
    stackView.addArrangedSubview(searchBar)
    stackView.addArrangedSubview(accessoryView)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: contentInsets.top),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInsets.left),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInsets.right),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInsets.bottom),
    ])

    self.stackView = stackView
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }
}
