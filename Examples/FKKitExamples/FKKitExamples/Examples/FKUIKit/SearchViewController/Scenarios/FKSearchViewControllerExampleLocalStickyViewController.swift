import FKUIKit
import UIKit

/// Local in-memory filter with ``FKSearchBarPlacement/stickyHeader`` (default).
final class FKSearchViewControllerExampleLocalStickyViewController: FKSearchViewController {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()

  init() {
    super.init(
      configuration: FKSearchViewControllerDefaults.localFilter(placement: .stickyHeader),
      placeholder: "Search fruits"
    )
    localFilterProvider = provider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Local · Sticky Header"
  }
}
