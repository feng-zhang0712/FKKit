import FKUIKit
import XCTest

final class FKListWindowingConfigurationTests: XCTestCase {
  func testInitClampsMaxItemCountToAtLeastOne() {
    let configuration = FKListWindowingConfiguration(maxItemCount: 0)

    XCTAssertEqual(configuration.maxItemCount, 1)
  }

  func testDefaultConfigurationDisablesWindowingWithHeadTrimStrategy() {
    let configuration = FKListWindowingConfiguration()

    XCTAssertFalse(configuration.isEnabled)
    XCTAssertEqual(configuration.maxItemCount, 500)
    XCTAssertEqual(configuration.trimStrategy, .removeOldestItemsFromHead)
  }
}
