import FKCompositeKit
import UIKit

/// Demonstrates ``FKBaseSearchIntegration`` with a ``UISearchController`` on ``navigationItem``.
final class FKBaseSearchExampleViewController: FKBaseViewController, UISearchResultsUpdating {

  private let stack = UIStackView()
  private let bodyLabel = UILabel()
  private let searchController = UISearchController(searchResultsController: nil)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Search"
  }

  override func setupUI() {
    super.setupUI()
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = "Filter the note below"
    FKBaseSearchIntegration.install(searchController, on: self, hidesNavigationBarDuringPresentation: true)

    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    bodyLabel.numberOfLines = 0
    bodyLabel.font = .preferredFont(forTextStyle: .body)
    bodyLabel.text = "This paragraph is filtered live by the search bar. Try typing “demo” or “FK”."

    stack.addArrangedSubview(bodyLabel)
    view.addSubview(stack)
  }

  override func setupConstraints() {
    super.setupConstraints()
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  func updateSearchResults(for searchController: UISearchController) {
    let q = searchController.searchBar.text?.lowercased() ?? ""
    let full = "This paragraph is filtered live by the search bar. Try typing “demo” or “FK”."
    if q.isEmpty {
      bodyLabel.text = full
      return
    }
    bodyLabel.text = full.lowercased().contains(q)
      ? "Match: \(full)"
      : "No match for “\(searchController.searchBar.text ?? "")”."
  }
}
