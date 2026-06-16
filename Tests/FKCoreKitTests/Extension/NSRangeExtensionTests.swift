import FKCoreKit
import XCTest

final class NSRangeExtensionTests: XCTestCase {
  func testIsValidRejectsNotFoundAndOutOfBoundsRanges() {
    XCTAssertFalse(NSRange(location: NSNotFound, length: 1).fk_isValid(forUTF16Length: 10))
    XCTAssertFalse(NSRange(location: 8, length: 5).fk_isValid(forUTF16Length: 10))
    XCTAssertTrue(NSRange(location: 2, length: 3).fk_isValid(forUTF16Length: 10))
  }

  func testClampedReducesLengthToFitUTF16Bounds() {
    let clamped = NSRange(location: 8, length: 5).fk_clamped(toUTF16Length: 10)

    XCTAssertEqual(clamped.location, 8)
    XCTAssertEqual(clamped.length, 2)
  }

  func testClampedReturnsZeroRangeForInvalidLocation() {
    let clamped = NSRange(location: NSNotFound, length: 3).fk_clamped(toUTF16Length: 10)

    XCTAssertEqual(clamped.location, 0)
    XCTAssertEqual(clamped.length, 0)
  }
}
