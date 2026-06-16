import FKCoreKit
import XCTest

final class OptionalExtensionTests: XCTestCase {
  func testOrReturnsDefaultWhenNil() {
    XCTAssertEqual(Int?.none.fk_or(42), 42)
  }

  func testOrReturnsWrappedValueWhenPresent() {
    XCTAssertEqual(Optional(7).fk_or(42), 7)
  }

  func testFilterReturnsNilWhenPredicateFails() {
    XCTAssertNil(Optional(3).fk_filter { $0 > 5 })
    XCTAssertEqual(Optional(8).fk_filter { $0 > 5 }, 8)
  }

  func testIsNilOrEmptyForOptionalCollection() {
    XCTAssertTrue((Optional<[Int]>.none).fk_isNilOrEmpty)
    XCTAssertTrue(Optional([Int]()).fk_isNilOrEmpty)
    XCTAssertFalse(Optional([1]).fk_isNilOrEmpty)
  }
}
