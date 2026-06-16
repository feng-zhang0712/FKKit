import FKCoreKit
import XCTest

final class CollectionExtensionTests: XCTestCase {
  func testSafeSubscriptReturnsNilWhenOutOfRange() {
    let values = [10, 20, 30]
    XCTAssertNil(values[fk_safe: 99])
    XCTAssertEqual(values[fk_safe: 1], 20)
  }

  func testCountOfElementReturnsOccurrences() {
    XCTAssertEqual([1, 2, 1, 3, 1].fk_count(of: 1), 3)
    XCTAssertEqual([1, 2, 3].fk_count(of: 9), 0)
  }

  func testLastWhereScansFromEnd() {
    let values = [1, 2, 3, 4, 3]
    XCTAssertEqual(values.fk_last(where: { $0 == 3 }), 3)
    XCTAssertNil(values.fk_last(where: { $0 == 9 }))
  }
}
