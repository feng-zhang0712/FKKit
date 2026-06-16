import FKUIKit
import XCTest

final class FKAlertMotionConfigurationTests: XCTestCase {
  func testDefaultConfigurationRespectsReduceMotion() {
    let configuration = FKAlertMotionConfiguration()

    XCTAssertTrue(configuration.respectsReduceMotion)
  }

  func testConfigurationStoresCustomReduceMotionPreference() {
    let configuration = FKAlertMotionConfiguration(respectsReduceMotion: false)

    XCTAssertFalse(configuration.respectsReduceMotion)
  }
}
