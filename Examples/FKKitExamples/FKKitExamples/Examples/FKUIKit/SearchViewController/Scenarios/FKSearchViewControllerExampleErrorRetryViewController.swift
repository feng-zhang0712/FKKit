import FKUIKit
import UIKit

/// Failed remote search shows ``FKEmptyStateScenario/loadFailed``; retry calls ``retryCurrentSearch()``.
final class FKSearchViewControllerExampleErrorRetryViewController: FKSearchViewController {
  private let mockProvider = FKSearchViewControllerExampleSupport.MockResultsProvider()

  init() {
    var config = FKSearchViewControllerDefaults.remote(placement: .stickyHeader)
    config.loading.useSkeleton = false
    super.init(configuration: config, placeholder: "Type \"error\" to fail")
    mockProvider.failsWhenQueryContains = "error"
    resultsProvider = mockProvider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Remote · Error & Retry"
  }
}
