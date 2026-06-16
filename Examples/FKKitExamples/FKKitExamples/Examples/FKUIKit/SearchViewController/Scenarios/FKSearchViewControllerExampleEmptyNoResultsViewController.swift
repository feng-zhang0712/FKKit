import FKUIKit
import UIKit

/// Non-empty query with zero matches shows ``FKEmptyStateScenario/noSearchResult``.
final class FKSearchViewControllerExampleEmptyNoResultsViewController: FKSearchViewController {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()

  init() {
    var config = FKSearchViewControllerDefaults.localFilter(placement: .stickyHeader)
    config.empty.searchNoResultsScenario = .noSearchResult
    super.init(configuration: config, placeholder: "Try \"Durian\" or \"ZZZ\"")
    localFilterProvider = provider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Empty · No Results"
  }
}
