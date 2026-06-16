import FKCoreKit
import XCTest

final class SequenceExtensionTests: XCTestCase {
  func testGroupedKeepsLastElementForDuplicateKeys() {
    let grouped = ["aa", "ab", "ba"].fk_grouped { String($0.prefix(1)) }

    XCTAssertEqual(grouped["a"], "ab")
    XCTAssertEqual(grouped["b"], "ba")
  }

  func testGroupingBuildsArraysPerKey() {
    let grouped = [1, 2, 3, 4].fk_grouping { $0.isMultiple(of: 2) ? "even" : "odd" }

    XCTAssertEqual(grouped["odd"], [1, 3])
    XCTAssertEqual(grouped["even"], [2, 4])
  }

  func testNoneSatisfyReturnsTrueWhenPredicateNeverMatches() {
    XCTAssertTrue([2, 4, 6].fk_noneSatisfy { $0.isMultiple(of: 2) == false })
    XCTAssertFalse([2, 3].fk_noneSatisfy { $0 == 3 })
  }

  func testSumAddsNumericElements() {
    XCTAssertEqual([1, 2, 3].fk_sum(), 6)
    XCTAssertEqual([Int]().fk_sum(), 0)
  }
}
