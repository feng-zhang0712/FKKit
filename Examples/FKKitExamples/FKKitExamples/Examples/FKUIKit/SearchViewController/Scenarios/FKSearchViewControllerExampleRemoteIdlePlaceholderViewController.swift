import FKUIKit
import UIKit

/// ``FKSearchBehaviorConfiguration/showsResultsOnEmptyQuery`` with ``remoteIdleSnapshot`` placeholder rows.
final class FKSearchViewControllerExampleRemoteIdlePlaceholderViewController: FKSearchViewController {
  private let mockProvider = FKSearchViewControllerExampleSupport.MockResultsProvider()

  init() {
    var config = FKSearchViewControllerDefaults.remote(placement: .stickyHeader)
    config.behavior.showsResultsOnEmptyQuery = true
    config.loading.useSkeleton = false
    config.loading.searchBarLoading = false
    super.init(configuration: config, placeholder: "Clear field to see idle rows")
    remoteIdleSnapshot = FKSearchViewControllerExampleSupport.makeCatalogSnapshot()
    mockProvider.simulatedDelay = 0.6
    resultsProvider = mockProvider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Remote · Idle Placeholder"
  }
}
