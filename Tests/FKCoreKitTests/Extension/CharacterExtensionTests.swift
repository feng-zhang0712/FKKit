import FKCoreKit
import XCTest

final class CharacterExtensionTests: XCTestCase {
  func testIsASCIIDetectsSingleByteCharacters() {
    XCTAssertTrue(Character("A").fk_isASCII)
    XCTAssertFalse(Character("é").fk_isASCII)
  }

  func testIsNewlineDetectsLineBreakCharacters() {
    XCTAssertTrue(Character("\n").fk_isNewline)
    XCTAssertFalse(Character("a").fk_isNewline)
  }
}
