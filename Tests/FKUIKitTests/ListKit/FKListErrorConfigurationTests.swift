import FKUIKit
import XCTest

final class FKListErrorConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesLoadFailedScenario() {
    let configuration = FKListErrorConfiguration()

    XCTAssertFalse(configuration.preservesContentOnError)
    XCTAssertEqual(configuration.scenario, .loadFailed)
    XCTAssertFalse(configuration.animatesPresentation)
  }

  func testConfigurationStoresPreserveContentAndPrimaryActionOverride() {
    let configuration = FKListErrorConfiguration(
      preservesContentOnError: true,
      scenario: .noNetwork,
      overridesPrimaryActionTitle: "Try again"
    )

    XCTAssertTrue(configuration.preservesContentOnError)
    XCTAssertEqual(configuration.scenario, .noNetwork)
    XCTAssertEqual(configuration.overridesPrimaryActionTitle, "Try again")
  }
}
