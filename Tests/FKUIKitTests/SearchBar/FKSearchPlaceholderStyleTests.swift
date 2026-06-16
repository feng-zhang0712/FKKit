import FKUIKit
import XCTest

final class FKSearchPlaceholderStyleTests: XCTestCase {
  func testDefaultConfigurationUsesPlaceholderTextColor() {
    let style = FKSearchPlaceholderStyle()

    XCTAssertNil(style.font)
    XCTAssertEqual(style.textColor, .placeholderText)
  }

  func testConfigurationStoresCustomPlaceholderFont() {
    let font = UIFont.systemFont(ofSize: 14)
    let style = FKSearchPlaceholderStyle(font: font, textColor: .secondaryLabel)

    XCTAssertEqual(style.font, font)
    XCTAssertEqual(style.textColor, .secondaryLabel)
  }
}
