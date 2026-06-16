import FKUIKit
import XCTest

final class FKListAppearanceConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesSystemFontsAndDisabledAlpha() {
    let configuration = FKListAppearanceConfiguration()

    XCTAssertEqual(configuration.disabledAlpha, 0.4, accuracy: 0.001)
    XCTAssertEqual(configuration.titleColor, .label)
    XCTAssertEqual(configuration.subtitleColor, .secondaryLabel)
  }

  func testConfigurationStoresCustomDisabledAlpha() {
    let configuration = FKListAppearanceConfiguration(disabledAlpha: 0.25)

    XCTAssertEqual(configuration.disabledAlpha, 0.25, accuracy: 0.001)
  }
}
