import FKUIKit
import XCTest

final class FKSearchEmptyConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesNoSearchResultScenario() {
    let configuration = FKSearchEmptyConfiguration()

    XCTAssertEqual(configuration.searchNoResultsScenario, .noSearchResult)
    XCTAssertNil(configuration.remoteIdleScenario)
    XCTAssertNil(configuration.overridesTitle)
    XCTAssertNil(configuration.overridesMessage)
  }

  func testConfigurationStoresRemoteIdleScenarioAndOverrides() {
    let configuration = FKSearchEmptyConfiguration(
      remoteIdleScenario: .noMessages,
      overridesTitle: "Start typing",
      overridesMessage: "Search products by name"
    )

    XCTAssertEqual(configuration.remoteIdleScenario, .noMessages)
    XCTAssertEqual(configuration.overridesTitle, "Start typing")
    XCTAssertEqual(configuration.overridesMessage, "Search products by name")
  }
}
