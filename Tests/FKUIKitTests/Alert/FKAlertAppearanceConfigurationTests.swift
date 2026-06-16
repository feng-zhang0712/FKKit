import FKUIKit
import XCTest

final class FKAlertAppearanceConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesHeadlineTitleAndBodyMessageStyles() {
    let configuration = FKAlertAppearanceConfiguration()

    XCTAssertEqual(configuration.titleTextStyle, .headline)
    XCTAssertEqual(configuration.messageTextStyle, .body)
    XCTAssertEqual(configuration.iconSize, 40, accuracy: 0.001)
    XCTAssertNil(configuration.maxMessageHeight)
  }

  func testConfigurationStoresCustomSpacingAndIconSize() {
    let configuration = FKAlertAppearanceConfiguration(
      bodyItemSpacing: 12,
      actionSectionSpacing: 24,
      iconSize: 56
    )

    XCTAssertEqual(configuration.bodyItemSpacing, 12, accuracy: 0.001)
    XCTAssertEqual(configuration.actionSectionSpacing, 24, accuracy: 0.001)
    XCTAssertEqual(configuration.iconSize, 56, accuracy: 0.001)
  }
}
