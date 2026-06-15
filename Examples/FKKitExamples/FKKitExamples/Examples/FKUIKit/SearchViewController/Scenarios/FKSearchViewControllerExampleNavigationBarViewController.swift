import FKUIKit
import UIKit

/// ``FKSearchBarPlacement/navigationBar`` with cancel-on-focus navigation preset.
final class FKSearchViewControllerExampleNavigationBarViewController: FKSearchViewController {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()

  init() {
    var config = FKSearchViewControllerDefaults.localFilter(placement: .navigationBar)
    config.searchBar = FKSearchBarDefaults.navigationBar()
    super.init(configuration: config, placeholder: "Search fruits")
    localFilterProvider = provider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Navigation Bar"
    navigationItem.largeTitleDisplayMode = .never
  }
}
