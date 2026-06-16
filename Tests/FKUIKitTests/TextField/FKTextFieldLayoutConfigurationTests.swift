import FKUIKit
import XCTest

final class FKTextFieldLayoutConfigurationTests: XCTestCase {
  func testInitClampsTextAreaHeightAndInlineMessageSpacing() {
    let configuration = FKTextFieldLayoutConfiguration(
      textAreaHeight: 10,
      inlineMessageSpacing: -4
    )

    XCTAssertEqual(configuration.textAreaHeight, 28, accuracy: 0.001)
    XCTAssertEqual(configuration.inlineMessageSpacing, 0, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesFortyFourPointTextArea() {
    let configuration = FKTextFieldLayoutConfiguration()

    XCTAssertEqual(configuration.textAreaHeight, 44, accuracy: 0.001)
    XCTAssertEqual(configuration.contentInsets.left, 12, accuracy: 0.001)
  }
}
