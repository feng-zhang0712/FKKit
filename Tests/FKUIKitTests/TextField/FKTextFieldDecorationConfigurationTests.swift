import FKUIKit
import XCTest

final class FKTextFieldDecorationConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesBorderMode() {
    let configuration = FKTextFieldDecorationConfiguration()

    XCTAssertEqual(configuration.mode, .border)
  }

  func testConfigurationStoresUnderlineModeWithThicknessAndInsets() {
    let insets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    let configuration = FKTextFieldDecorationConfiguration(mode: .underline(thickness: 2, insets: insets))

    if case .underline(let thickness, let storedInsets) = configuration.mode {
      XCTAssertEqual(thickness, 2, accuracy: 0.001)
      XCTAssertEqual(storedInsets, insets)
    } else {
      XCTFail("Expected underline decoration mode")
    }
  }
}
