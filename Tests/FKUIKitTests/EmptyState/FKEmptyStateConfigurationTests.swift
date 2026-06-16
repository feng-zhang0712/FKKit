import FKUIKit
import XCTest

final class FKEmptyStateConfigurationTests: XCTestCase {
  func testScenarioLoadFailedUsesErrorPhase() {
    let config = FKEmptyStateConfiguration.scenario(.loadFailed)
    XCTAssertEqual(config.phase, .error)
  }

  func testScenarioNoSearchResultUsesEmptyPhaseAndNoResultsType() {
    let config = FKEmptyStateConfiguration.scenario(.noSearchResult)
    XCTAssertEqual(config.phase, .empty)
    XCTAssertEqual(config.type, .noResults)
  }

  func testScenarioNoNetworkIncludesPrimaryRetryAction() {
    let config = FKEmptyStateConfiguration.scenario(.noNetwork)
    XCTAssertNotNil(config.actions.primary)
  }
}
