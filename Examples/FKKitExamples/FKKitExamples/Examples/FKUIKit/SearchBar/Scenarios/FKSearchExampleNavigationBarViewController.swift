import FKUIKit
import UIKit

/// ``FKSearchBarNavigationHosting`` in `navigationItem.titleView` with cancel-on-focus.
final class FKSearchExampleNavigationBarViewController: UIViewController {

  private let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.navigationBar(), placeholder: "Search items")
  private let logView = FKSearchExampleSupport.makeEventLogTextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Navigation bar"
    view.backgroundColor = .systemGroupedBackground
    navigationItem.largeTitleDisplayMode = .never

    FKSearchBarNavigationHosting.install(searchBar, in: navigationItem, placeholder: "Search items")

    searchBar.callbacks.onSearchQueryChanged = { [weak self] query in
      FKSearchExampleSupport.appendLog(self?.logView ?? UITextView(), "query → \"\(query)\"")
    }
    searchBar.callbacks.onCancel = { [weak self] in
      FKSearchExampleSupport.appendLog(self?.logView ?? UITextView(), "cancel tapped")
    }
    searchBar.callbacks.onEditingDidBegin = { [weak self] in
      FKSearchExampleSupport.appendLog(self?.logView ?? UITextView(), "editing began — cancel appears")
    }

    let card = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel(
        "Focus the bar in the navigation title area. Cancel clears text and dismisses the keyboard (.clearAndResign)."
      ),
    ])

    card.translatesAutoresizingMaskIntoConstraints = false
    logView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(card)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      card.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      logView.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 12),
      logView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      logView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}
