import FKUIKit
import UIKit

/// Override ``emptyConfiguration(for:)`` for custom empty and error copy.
final class FKSearchViewControllerExampleCustomEmptyCopyViewController: FKSearchViewController {
  private let mockProvider = FKSearchViewControllerExampleSupport.MockResultsProvider()

  init() {
    var config = FKSearchViewControllerDefaults.remote(placement: .stickyHeader)
    config.loading.useSkeleton = false
    config.empty.overridesTitle = "Nothing matched"
    config.empty.overridesMessage = "Try a shorter keyword or check spelling."
    super.init(configuration: config, placeholder: "Remote or type \"error\"")
    mockProvider.failsWhenQueryContains = "error"
    mockProvider.simulatedDelay = 0.5
    resultsProvider = mockProvider
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func emptyConfiguration(for state: FKListPresentationState) -> FKEmptyStateConfiguration? {
    switch state {
    case .empty:
      var model = super.emptyConfiguration(for: state) ?? FKEmptyStateConfiguration.scenario(.noSearchResult)
      model.content.title = "No fruits found"
      model.content.description = "We could not find \"\(currentQueryLabel)\" in this demo dataset."
      return model
    case .error:
      var model = FKEmptyStateConfiguration.scenario(.loadFailed)
      model.phase = .error
      model.content.title = "Search unavailable"
      model.content.description = "Tap Retry to run the same query again."
      return model
    default:
      return super.emptyConfiguration(for: state)
    }
  }

  private var currentQueryLabel: String {
    switch presentationState {
    case .empty(let query, _), .error(let query, _), .loading(let query), .results(let query, _):
      return query
    default:
      return ""
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Empty Copy"
  }
}
