import FKUIKit
import UIKit

/// Local filter with search bar in ``FKSearchBarPlacement/tableHeader``.
final class FKSearchViewControllerExampleLocalTableHeaderViewController: FKSearchViewController {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()

  init() {
    super.init(
      configuration: FKSearchViewControllerDefaults.localFilter(placement: .tableHeader),
      placeholder: "Filter as table header"
    )
    localFilterProvider = provider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Local · Table Header"
  }
}
