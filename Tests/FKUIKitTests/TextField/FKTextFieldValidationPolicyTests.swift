import FKUIKit
import XCTest

final class FKTextFieldValidationPolicyTests: XCTestCase {
  func testInitClampsNegativeDebounceIntervalToZero() {
    let policy = FKTextFieldValidationPolicy(debounceInterval: -0.5)

    XCTAssertEqual(policy.debounceInterval, 0, accuracy: 0.001)
  }

  func testDefaultPolicyValidatesOnChangeAndIgnoresEmptyInput() {
    let policy = FKTextFieldValidationPolicy()

    XCTAssertEqual(policy.trigger, .onChange)
    XCTAssertTrue(policy.ignoresEmptyInput)
    XCTAssertTrue(policy.marksSuccessOnAsyncPass)
    XCTAssertEqual(policy.debounceInterval, 0.2, accuracy: 0.001)
  }
}
