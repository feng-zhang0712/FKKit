import FKUIKit
import XCTest

final class FKTextFieldDefaultFormatterTests: XCTestCase {
  private let formatter = FKTextFieldDefaultFormatter()

  func testPhoneNumberFormatterGroupsDigitsAndStripsNonDigits() {
    let rule = FKTextFieldInputRule(formatType: .phoneNumber)
    let result = formatter.format(text: "138-0013-8000", rule: rule)

    XCTAssertEqual(result.rawText, "13800138000")
    XCTAssertEqual(result.formattedText, "138 0013 8000")
  }

  func testNumericFormatterFiltersNonDigits() {
    let rule = FKTextFieldInputRule(formatType: .numeric, allowedInput: .numeric)
    let result = formatter.format(text: "12a34", rule: rule)

    XCTAssertEqual(result.rawText, "1234")
    XCTAssertTrue(result.removedIllegalCharacters)
  }

  func testAmountFormatterLimitsDecimalDigits() {
    let rule = FKTextFieldInputRule(formatType: .amount(maxIntegerDigits: 5, decimalDigits: 2))
    let result = formatter.format(text: "12345.678", rule: rule)

    XCTAssertEqual(result.rawText, "12345.67")
    XCTAssertEqual(result.formattedText, "12,345.67")
  }
}
