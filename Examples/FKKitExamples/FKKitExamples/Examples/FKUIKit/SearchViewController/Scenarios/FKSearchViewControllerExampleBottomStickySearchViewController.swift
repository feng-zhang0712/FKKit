import FKUIKit
import UIKit

/// Local filter with ``FKSearchBarPlacement/stickyFooter`` — search bar pins above the keyboard via ``UIView/keyboardLayoutGuide``.
final class FKSearchViewControllerExampleBottomStickySearchViewController: FKSearchViewController {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()

  init() {
    var config = FKSearchViewControllerDefaults.localFilter(placement: .stickyFooter)
    config.behavior.focusesSearchOnAppear = true
    super.init(configuration: config, placeholder: "Search fruits")
    localFilterProvider = provider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Bottom · Keyboard Aware"
  }
}
