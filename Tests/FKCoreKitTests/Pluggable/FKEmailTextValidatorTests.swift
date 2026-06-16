import FKCoreKit
import XCTest

final class FKEmailTextValidatorTests: XCTestCase {
  private let validator = FKEmailTextValidator()

  func testAcceptsWellFormedEmailAddress() {
    if case .valid = validator.validate(rawText: "user@example.com", displayText: "user@example.com", rule: .default) {
      // expected
    } else {
      XCTFail("Expected valid email")
    }
  }

  func testRejectsMalformedEmailAddress() {
    if case .invalid = validator.validate(rawText: "not-an-email", displayText: "not-an-email", rule: .default) {
      // expected
    } else {
      XCTFail("Expected invalid email")
    }
  }

  func testEmptyInputHonorsAllowsEmptyRule() {
    let required = validator.validate(rawText: "", displayText: "", rule: FKEmailValidationRule(allowsEmpty: false))
    let optional = validator.validate(rawText: "", displayText: "", rule: FKEmailValidationRule(allowsEmpty: true))

    if case .invalid = required {
      // expected
    } else {
      XCTFail("Expected empty email to be invalid when allowsEmpty is false")
    }
    if case .valid = optional {
      // expected
    } else {
      XCTFail("Expected empty email to be valid when allowsEmpty is true")
    }
  }
}
