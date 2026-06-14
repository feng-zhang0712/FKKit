import UIKit

/// Hosts ``FKSearchBar`` and an optional accessory for sticky-header placement.
@MainActor
final class FKSearchChromeContainerView: UIView {
  let searchBar: FKSearchBar
  private let stackView = UIStackView()

  init(
    searchBar: FKSearchBar,
    accessoryView: UIView? = nil,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
  ) {
    self.searchBar = searchBar
    super.init(frame: .zero)
    backgroundColor = .systemBackground
    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.addArrangedSubview(searchBar)
    if let accessoryView {
      accessoryView.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(accessoryView)
    }
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: contentInsets.top),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInsets.left),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInsets.right),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInsets.bottom),
    ])
  }

  func setAccessoryView(_ accessoryView: UIView?) {
    if stackView.arrangedSubviews.count > 1 {
      let existing = stackView.arrangedSubviews[1]
      stackView.removeArrangedSubview(existing)
      existing.removeFromSuperview()
    }
    guard let accessoryView else { return }
    accessoryView.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(accessoryView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }
}
