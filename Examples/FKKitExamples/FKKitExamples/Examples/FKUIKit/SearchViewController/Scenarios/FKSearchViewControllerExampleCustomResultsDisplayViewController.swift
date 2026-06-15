import FKUIKit
import UIKit

/// Custom results child conforming to ``FKSearchResultsDisplaying`` instead of embedded ListKit defaults.
final class FKSearchViewControllerExampleCustomResultsDisplayViewController: FKSearchViewController {
  private let mockProvider = FKSearchViewControllerExampleSupport.MockResultsProvider()

  init() {
    var config = FKSearchViewControllerDefaults.remote(placement: .stickyHeader)
    config.presentation = .customResultsViewController
    config.loading.useSkeleton = false
    super.init(configuration: config, placeholder: "Custom results surface")
    resultsProvider = mockProvider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func makeResultsViewController() -> UIViewController {
    FKSearchViewControllerExampleLabelResultsViewController()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Results VC"
  }
}

/// Minimal non-list results surface driven by ``FKSearchResultsDisplaying``.
final class FKSearchViewControllerExampleLabelResultsViewController: UIViewController, FKSearchResultsDisplaying {
  private let statusLabel = UILabel()
  private let detailLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    statusLabel.font = .preferredFont(forTextStyle: .headline)
    detailLabel.font = .preferredFont(forTextStyle: .body)
    detailLabel.numberOfLines = 0
    detailLabel.textColor = .secondaryLabel

    let stack = UIStackView(arrangedSubviews: [statusLabel, detailLabel])
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
      stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])

    statusLabel.text = "Idle"
    detailLabel.text = "Type to search the catalog."
  }

  func applySearchResultsUpdate(
    _ update: FKSearchResultsPresentationUpdate,
    from searchViewController: FKSearchViewController
  ) {
    switch update {
    case .idle:
      statusLabel.text = "Idle"
      detailLabel.text = "Type to search the catalog."
    case .loading(let query):
      statusLabel.text = "Loading"
      detailLabel.text = "Searching for \"\(query)\"…"
    case .results(let query, let snapshot):
      statusLabel.text = "Results"
      detailLabel.text = "Query \"\(query)\" returned \(snapshot.totalItemCount) item(s)."
    case .empty(let query, let scenario):
      statusLabel.text = "Empty"
      detailLabel.text = "No matches for \"\(query)\" (\(scenario))."
    case .error(let query, let error):
      statusLabel.text = "Error"
      detailLabel.text = "Search for \"\(query)\" failed: \(error)"
    }
  }
}
