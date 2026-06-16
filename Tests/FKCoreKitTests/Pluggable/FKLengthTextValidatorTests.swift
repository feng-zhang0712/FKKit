import FKCoreKit
import XCTest

final class FKLengthTextValidatorTests: XCTestCase {
  private let validator = FKLengthTextValidator()

  func testAcceptsTextWithinInclusiveBounds() {
    let rule = FKLengthValidationRule(minimum: 2, maximum: 4)

    if case .valid = validator.validate(rawText: "abc", displayText: "abc", rule: rule) {
      // expected
    } else {
      XCTFail("Expected valid result for in-range text")
    }
  }

  func testRejectsTextShorterThanMinimum() {
    let rule = FKLengthValidationRule(minimum: 3, maximum: 8)

    if case .invalid = validator.validate(rawText: "ab", displayText: "ab", rule: rule) {
      // expected
    } else {
      XCTFail("Expected invalid result for short text")
    }
  }

  func testRejectsTextLongerThanMaximum() {
    let rule = FKLengthValidationRule(minimum: 1, maximum: 2)

    if case .invalid = validator.validate(rawText: "abcd", displayText: "abcd", rule: rule) {
      // expected
    } else {
      XCTFail("Expected invalid result for long text")
    }
  }
}
