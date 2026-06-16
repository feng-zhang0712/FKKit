import FKUIKit
import XCTest

final class FKEmptyStateTypographyTests: XCTestCase {
  func testDefaultConfigurationUsesCenterAlignedSystemFonts() {
    let typography = FKEmptyStateTypography()

    XCTAssertEqual(typography.titleColor, .label)
    XCTAssertEqual(typography.descriptionColor, .secondaryLabel)
    XCTAssertEqual(typography.textAlignment, .center)
  }

  func testConfigurationStoresCustomTextAlignment() {
    let typography = FKEmptyStateTypography(textAlignment: .left)

    XCTAssertEqual(typography.textAlignment, .left)
  }
}
