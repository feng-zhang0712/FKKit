import FKUIKit
import XCTest

final class FKListEmptyConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesNoSearchResultWithoutAnimation() {
    let configuration = FKListEmptyConfiguration()

    XCTAssertEqual(configuration.scenario, .noSearchResult)
    XCTAssertNil(configuration.overridesTitle)
    XCTAssertFalse(configuration.animatesPresentation)
  }

  func testConfigurationStoresOverridesAndAnimationFlag() {
    let configuration = FKListEmptyConfiguration(
      scenario: .noOrders,
      overridesTitle: "No orders yet",
      overridesMessage: "Place your first order",
      animatesPresentation: true
    )

    XCTAssertEqual(configuration.scenario, .noOrders)
    XCTAssertEqual(configuration.overridesTitle, "No orders yet")
    XCTAssertEqual(configuration.overridesMessage, "Place your first order")
    XCTAssertTrue(configuration.animatesPresentation)
  }
}
