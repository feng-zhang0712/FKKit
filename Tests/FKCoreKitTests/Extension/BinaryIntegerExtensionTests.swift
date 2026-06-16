import FKCoreKit
import XCTest

final class BinaryIntegerExtensionTests: XCTestCase {
  func testIsEvenAndIsOddDetectParity() {
    XCTAssertTrue(4.fk_isEven)
    XCTAssertFalse(4.fk_isOdd)
    XCTAssertTrue(7.fk_isOdd)
    XCTAssertFalse(7.fk_isEven)
  }

  func testByteCountDescriptionFormatsNonEmptyLabel() {
    XCTAssertFalse(1024.fk_byteCountDescription.isEmpty)
  }
}
