import FKUIKit
import XCTest

final class FKImageViewInteractionConfigurationTests: XCTestCase {
  func testDefaultConfigurationDisablesHighlightAndUsesDefaultDebounce() {
    let configuration = FKImageViewInteractionConfiguration()

    XCTAssertFalse(configuration.highlightOnPress)
    XCTAssertEqual(configuration.retryDebounceInterval, 0.3, accuracy: 0.001)
  }

  func testConfigurationStoresCustomRetryDebounceInterval() {
    let configuration = FKImageViewInteractionConfiguration(
      highlightOnPress: true,
      retryDebounceInterval: 0.75
    )

    XCTAssertTrue(configuration.highlightOnPress)
    XCTAssertEqual(configuration.retryDebounceInterval, 0.75, accuracy: 0.001)
  }
}
