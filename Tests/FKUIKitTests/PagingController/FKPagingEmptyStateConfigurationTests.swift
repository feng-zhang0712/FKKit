import FKUIKit
import XCTest

final class FKPagingEmptyStateConfigurationTests: XCTestCase {
  func testDefaultConfigurationIsEnabledWithLocalizedMessage() {
    let configuration = FKPagingEmptyStateConfiguration()

    XCTAssertTrue(configuration.isEnabled)
    XCTAssertFalse(configuration.message.isEmpty)
  }

  func testConfigurationStoresCustomMessageAndDisabledFlag() {
    let configuration = FKPagingEmptyStateConfiguration(
      isEnabled: false,
      message: "No tabs configured"
    )

    XCTAssertFalse(configuration.isEnabled)
    XCTAssertEqual(configuration.message, "No tabs configured")
  }
}
