import FKUIKit
import UIKit

/// Custom idle search-page body via ``makeSearchContentViewController()``.
final class FKSearchViewControllerExampleCustomSearchContentViewController: FKSearchViewController {
  private let provider = FruitProvider()

  init() {
    var config = FKSearchViewControllerDefaults.localFilter(placement: .stickyHeader)
    config.presentation = .customIdleEmbeddedResults
    super.init(configuration: config, placeholder: "Search fruits")
    localFilterProvider = provider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func makeSearchContentViewController() -> UIViewController? {
    FKSearchViewControllerExampleDiscoveryViewController(
      titleText: "Suggested searches",
      items: ["Apple", "Banana", "Cherry"]
    ) { [weak self] term in
      self?.setQuery(term, options: .withSearchQuery)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Search Page"
  }
}

private final class FruitProvider: NSObject, FKSearchLocalFilterProviding {
  private let baseline = FKSearchViewControllerExampleSupport.makeFruitBaselineSnapshot()

  var baselineSnapshot: FKListSnapshot { baseline }

  func filteredSnapshot(for query: String) -> FKListSnapshot {
    FKSearchViewControllerExampleSupport.filteredFruitSnapshot(for: query)
  }
}
