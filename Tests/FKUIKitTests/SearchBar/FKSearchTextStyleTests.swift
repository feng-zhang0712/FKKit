import FKUIKit
import XCTest

final class FKSearchTextStyleTests: XCTestCase {
  func testDefaultConfigurationUsesBodyFontAndLabelColor() {
    let style = FKSearchTextStyle()

    XCTAssertEqual(style.font, .preferredFont(forTextStyle: .body))
    XCTAssertEqual(style.textColor, .label)
  }

  func testConfigurationStoresCustomFontAndTextColor() {
    let font = UIFont.systemFont(ofSize: 15, weight: .medium)
    let style = FKSearchTextStyle(font: font, textColor: .systemRed)

    XCTAssertEqual(style.font, font)
    XCTAssertEqual(style.textColor, .systemRed)
  }
}
