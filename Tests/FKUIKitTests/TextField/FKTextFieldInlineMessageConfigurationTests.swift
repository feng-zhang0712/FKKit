import FKUIKit
import XCTest

final class FKTextFieldInlineMessageConfigurationTests: XCTestCase {
  func testDefaultConfigurationHidesInlineErrorMessage() {
    let configuration = FKTextFieldInlineMessageConfiguration()

    XCTAssertFalse(configuration.showsErrorMessage)
    XCTAssertEqual(configuration.errorColor, .systemRed)
    XCTAssertEqual(configuration.successColor, .systemGreen)
  }

  func testConfigurationStoresShowsErrorMessageFlag() {
    let configuration = FKTextFieldInlineMessageConfiguration(showsErrorMessage: true)

    XCTAssertTrue(configuration.showsErrorMessage)
  }
}
