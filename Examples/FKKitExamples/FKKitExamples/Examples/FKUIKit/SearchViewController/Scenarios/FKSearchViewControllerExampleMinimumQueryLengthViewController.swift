import FKUIKit
import UIKit

/// ``FKSearchDebounceConfiguration/minimumQueryLengthForSearchCallback`` — queries shorter than 3 chars are ignored.
final class FKSearchViewControllerExampleMinimumQueryLengthViewController: FKSearchViewController {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()

  init() {
    var config = FKSearchViewControllerDefaults.localFilter(placement: .stickyHeader)
    config.searchBar.debounce.minimumQueryLengthForSearchCallback = 3
    super.init(configuration: config, placeholder: "Min 3 characters")
    localFilterProvider = provider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Minimum Query Length"
  }
}
