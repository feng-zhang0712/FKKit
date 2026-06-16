import FKUIKit
import XCTest

final class FKTextFieldCounterConfigurationTests: XCTestCase {
  func testDefaultConfigurationDisablesCounter() {
    let configuration = FKTextFieldCounterConfiguration()

    XCTAssertFalse(configuration.isEnabled)
    XCTAssertNil(configuration.maxCount)
  }

  func testConfigurationStoresEnabledFlagAndMaxCount() {
    let configuration = FKTextFieldCounterConfiguration(isEnabled: true, maxCount: 120)

    XCTAssertTrue(configuration.isEnabled)
    XCTAssertEqual(configuration.maxCount, 120)
  }
}
