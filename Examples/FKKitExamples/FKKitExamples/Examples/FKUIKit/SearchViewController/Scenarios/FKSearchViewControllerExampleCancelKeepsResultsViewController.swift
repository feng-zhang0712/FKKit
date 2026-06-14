import FKUIKit
import UIKit

/// Cancel with ``FKSearchBehaviorConfiguration/cancelRestoresBaseline`` set to `false` keeps filtered rows.
final class FKSearchViewControllerExampleCancelKeepsResultsViewController: FKSearchViewController {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()

  init() {
    var config = FKSearchViewControllerDefaults.localFilter(placement: .navigationBar)
    config.searchBar = FKSearchBarDefaults.navigationBar()
    config.behavior.cancelRestoresBaseline = false
    super.init(configuration: config, placeholder: "Filter then Cancel")
    localFilterProvider = provider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Cancel · Keep Results"
    navigationItem.largeTitleDisplayMode = .never
  }
}
