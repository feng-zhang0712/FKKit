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

  func testBankCardRequiresTwelveToTwentyFourDigitsWhenNonEmpty() {
    let rule = FKTextFieldInputRule(formatType: .bankCard)

    XCTAssertTrue(validator.validate(rawText: "6222021234567890", formattedText: "", rule: rule).isValid)
    XCTAssertFalse(validator.validate(rawText: "62220212345", formattedText: "", rule: rule).isValid)
    let emptyResult = validator.validate(rawText: "", formattedText: "", rule: rule)
    XCTAssertFalse(emptyResult.isValid)
    XCTAssertNil(emptyResult.message)
  }

  func testVerificationCodeRequiresExactLength() {
    let rule = FKTextFieldInputRule(formatType: .verificationCode(length: 6, allowsAlphabet: false))

    XCTAssertTrue(validator.validate(rawText: "123456", formattedText: "", rule: rule).isValid)
    XCTAssertFalse(validator.validate(rawText: "12345", formattedText: "", rule: rule).isValid)
  }

  func testPasswordStrengthRequiresMixedCaseAndDigit() {
    let rule = FKTextFieldInputRule(formatType: .password(minLength: 8, maxLength: 64, validatesStrength: true))

    XCTAssertTrue(validator.validate(rawText: "Abcdef1!", formattedText: "", rule: rule).isValid)
    XCTAssertFalse(validator.validate(rawText: "abcdefgh", formattedText: "", rule: rule).isValid)
  }

  func testEighteenDigitIDCardChecksumValidation() {
    let rule = FKTextFieldInputRule(formatType: .idCard)
    let valid = validator.validate(rawText: "11010519491231002X", formattedText: "", rule: rule)
    let invalid = validator.validate(rawText: "110105194912310021", formattedText: "", rule: rule)

    XCTAssertTrue(valid.isValid)
    XCTAssertFalse(invalid.isValid)
  }
}
