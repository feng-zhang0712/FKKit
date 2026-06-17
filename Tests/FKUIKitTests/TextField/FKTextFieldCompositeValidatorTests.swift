import FKUIKit
import XCTest

final class FKTextFieldCompositeValidatorTests: XCTestCase {
  func testCompositeValidatorShortCircuitsOnFirstFailure() {
    let validator = FKTextFieldCompositeValidator(rules: [
      .required(message: "Required"),
      .minLength(3, message: "Too short"),
    ])

    let rule = FKTextFieldInputRule(formatType: .alphaNumeric)
    let emptyResult = validator.validate(rawText: "", formattedText: "", rule: rule)
    XCTAssertFalse(emptyResult.isValid)
    XCTAssertEqual(emptyResult.message, "Required")

    let shortResult = validator.validate(rawText: "ab", formattedText: "ab", rule: rule)
    XCTAssertFalse(shortResult.isValid)
    XCTAssertEqual(shortResult.message, "Too short")
  }

  func testCompositeValidatorReturnsValidWhenAllRulesPass() {
    let validator = FKTextFieldCompositeValidator(rules: [
      .required(),
      .minLength(2),
      .maxLength(10),
      .regex("^[A-Za-z]+$"),
    ])

    let rule = FKTextFieldInputRule(formatType: .alphaNumeric)
    let result = validator.validate(rawText: "hello", formattedText: "hello", rule: rule)

    XCTAssertTrue(result.isValid)
    XCTAssertNil(result.message)
  }
}
