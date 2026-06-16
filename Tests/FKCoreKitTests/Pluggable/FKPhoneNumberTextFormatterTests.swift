import FKCoreKit
import XCTest

final class FKPhoneNumberTextFormatterTests: XCTestCase {
  private let formatter = FKPhoneNumberTextFormatter()

  func testGroupsDigitsAsThreeFourFourWithSpaces() {
    let result = formatter.format(text: "13800138000", rule: .default)

    XCTAssertEqual(result.rawText, "13800138000")
    XCTAssertEqual(result.displayText, "138 0013 8000")
  }

  func testStripsNonDigitsAndCapsAtMaxDigits() {
    let result = formatter.format(text: "138-0013-8000-999", rule: FKPhoneNumberFormattingRule(maxDigits: 11))

    XCTAssertEqual(result.rawText, "13800138000")
    XCTAssertEqual(result.displayText, "138 0013 8000")
  }

  func testCountryCodeDigitsAreIncludedBeforeMaxDigitCap() {
    let result = formatter.format(text: "+86 138-0013-8000", rule: .default)

    XCTAssertEqual(result.rawText, "86138001380")
    XCTAssertEqual(result.displayText, "861 3800 1380")
  }

  func testEmptyInputProducesEmptyRawAndDisplayText() {
    let result = formatter.format(text: "", rule: .default)

    XCTAssertEqual(result.rawText, "")
    XCTAssertEqual(result.displayText, "")
  }
}
