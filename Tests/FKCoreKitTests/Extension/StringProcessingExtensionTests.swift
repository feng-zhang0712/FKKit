import FKCoreKit
import XCTest

final class StringProcessingExtensionTests: XCTestCase {
  func testRemovingAllWhitespaceStripsSpacesAndNewlines() {
    XCTAssertEqual("a b\nc".fk_removingAllWhitespace, "abc")
  }

  func testMaskedPhoneKeepsFirstThreeAndLastFourDigits() {
    XCTAssertEqual("13812345678".fk_maskedPhone(), "138****5678")
    XCTAssertEqual("123".fk_maskedPhone(), "123")
  }

  func testMaskedEmailMasksLocalPartAndPreservesDomain() {
    XCTAssertEqual("user.name@example.com".fk_maskedEmail(), "u*******e@example.com")
  }
}
