import FKCoreKit
import XCTest

final class FKBusinessMaskerTests: XCTestCase {
  private let masker = FKBusinessMasker()

  func testMaskPhoneKeepsFirstThreeAndLastFourDigits() {
    XCTAssertEqual(masker.maskPhone("13800138000"), "138****8000")
  }

  func testMaskEmailPreservesDomain() {
    XCTAssertEqual(masker.maskEmail("user@example.com"), "u***@example.com")
  }

  func testMaskIDCardKeepsPrefixAndSuffixForLongInput() {
    XCTAssertEqual(masker.maskIDCard("110101199001011234"), "110101********1234")
  }

  func testMaskReturnsOriginalWhenPrefixPlusSuffixCoversInput() {
    XCTAssertEqual(masker.mask("abc", keepPrefix: 2, keepSuffix: 2), "abc")
  }
}
