import FKUIKit
import XCTest

final class FKTextFieldDefaultValidatorTests: XCTestCase {
  private let validator = FKTextFieldDefaultValidator()

  func testPhoneNumberRequiresElevenDigitsWhenNonEmpty() {
    let rule = FKTextFieldInputRule(formatType: .phoneNumber)

    XCTAssertTrue(validator.validate(rawText: "13800138000", formattedText: "", rule: rule).isValid)
    XCTAssertFalse(validator.validate(rawText: "1380013800", formattedText: "", rule: rule).isValid)
    XCTAssertFalse(validator.validate(rawText: "", formattedText: "", rule: rule).isValid)
    XCTAssertNil(validator.validate(rawText: "", formattedText: "", rule: rule).message)
  }

  func testEmailValidationAcceptsWellFormedAddress() {
    let rule = FKTextFieldInputRule(formatType: .email)

    XCTAssertTrue(validator.validate(rawText: "user@example.com", formattedText: "", rule: rule).isValid)
    XCTAssertFalse(validator.validate(rawText: "not-an-email", formattedText: "", rule: rule).isValid)
  }

  func testMinLengthDoesNotFailEmptyInput() {
    let rule = FKTextFieldInputRule(formatType: .numeric, minLength: 3)

    XCTAssertTrue(validator.validate(rawText: "", formattedText: "", rule: rule).isValid)
    XCTAssertFalse(validator.validate(rawText: "12", formattedText: "", rule: rule).isValid)
  }

  func testFifteenDigitIDCardIsStructurallyValid() {
    let rule = FKTextFieldInputRule(formatType: .idCard)
    let result = validator.validate(rawText: "110101900101123", formattedText: "", rule: rule)
    XCTAssertTrue(result.isValid)
  }
}
