import FKUIKit
import UIKit

/// Remote mock API with ``FKSearchViewControllerLoadingConfiguration/searchBarLoading`` and cancel abort.
final class FKSearchViewControllerExampleRemoteLoadingViewController: FKSearchViewController {
  private let mockProvider = FKSearchViewControllerExampleSupport.MockResultsProvider()

  init() {
    var config = FKSearchViewControllerDefaults.remote(placement: .stickyHeader)
    config.loading.useSkeleton = true
    config.loading.searchBarLoading = true
    super.init(configuration: config, placeholder: "Search catalog (mock API)")
    resultsProvider = mockProvider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Remote · Loading"
  }
}
