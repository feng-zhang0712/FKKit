import FKUIKit
import UIKit

/// ``FKSearchBehaviorConfiguration/focusesSearchOnAppear`` auto-focuses the search field.
final class FKSearchViewControllerExampleFocusOnAppearViewController: FKSearchViewController {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()

  init() {
    var config = FKSearchViewControllerDefaults.localFilter(placement: .stickyHeader)
    config.behavior.focusesSearchOnAppear = true
    super.init(configuration: config, placeholder: "Auto-focused on appear")
    localFilterProvider = provider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Focus on Appear"
  }
}
