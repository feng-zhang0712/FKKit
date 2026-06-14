import FKUIKit
import UIKit

/// Cancel with ``FKSearchBehaviorConfiguration/cancelRestoresBaseline`` restores the full fruit list.
final class FKSearchViewControllerExampleCancelRestoresBaselineViewController: FKSearchViewController {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()

  init() {
    var config = FKSearchViewControllerDefaults.localFilter(placement: .navigationBar)
    config.searchBar = FKSearchBarDefaults.navigationBar()
    config.behavior.cancelRestoresBaseline = true
    super.init(configuration: config, placeholder: "Filter then Cancel")
    localFilterProvider = provider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Cancel · Restore Baseline"
    navigationItem.largeTitleDisplayMode = .never
  }
}
