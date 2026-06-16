import FKUIKit
import XCTest

final class FKTextFieldValidationFeedbackConfigurationTests: XCTestCase {
  func testDefaultConfigurationDisablesShakeFeedback() {
    let configuration = FKTextFieldValidationFeedbackConfiguration()

    XCTAssertFalse(configuration.shakesOnInvalid)
    XCTAssertEqual(configuration.shakeAmplitude, 10, accuracy: 0.001)
    XCTAssertEqual(configuration.shakeCount, 4)
    XCTAssertEqual(configuration.shakeDuration, 0.35, accuracy: 0.001)
  }

  func testConfigurationStoresCustomShakeParameters() {
    let configuration = FKTextFieldValidationFeedbackConfiguration(
      shakesOnInvalid: true,
      shakeAmplitude: 6,
      shakeCount: 2,
      shakeDuration: 0.2
    )

    XCTAssertTrue(configuration.shakesOnInvalid)
    XCTAssertEqual(configuration.shakeAmplitude, 6, accuracy: 0.001)
    XCTAssertEqual(configuration.shakeCount, 2)
    XCTAssertEqual(configuration.shakeDuration, 0.2, accuracy: 0.001)
  }
}
