import FKCoreKit
import XCTest

final class FKBankCardTextFormatterTests: XCTestCase {
  private let formatter = FKBankCardTextFormatter()

  func testGroupsSixteenDigitsIntoFourBlocks() {
    let result = formatter.format(text: "4111111111111111", rule: .default)

    XCTAssertEqual(result.rawText, "4111111111111111")
    XCTAssertEqual(result.displayText, "4111 1111 1111 1111")
  }

  func testStripsNonDigitsAndCapsAtMaxDigits() {
    let result = formatter.format(text: "4111-1111-1111-1111-9999", rule: FKBankCardFormattingRule(maxDigits: 16))

    XCTAssertEqual(result.rawText, "4111111111111111")
    XCTAssertEqual(result.displayText, "4111 1111 1111 1111")
  }
}
