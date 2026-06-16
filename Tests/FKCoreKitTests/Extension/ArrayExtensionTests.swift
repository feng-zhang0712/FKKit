import FKCoreKit
import XCTest

final class ArrayExtensionTests: XCTestCase {
  func testChunkedSplitsIntoFixedSizeGroups() {
    XCTAssertEqual([1, 2, 3, 4, 5].fk_chunked(into: 2), [[1, 2], [3, 4], [5]])
    XCTAssertEqual([1, 2, 3].fk_chunked(into: 0), [])
  }

  func testUniquedPreservesOrderWhileRemovingDuplicates() {
    XCTAssertEqual([1, 2, 1, 3, 2].fk_uniqued, [1, 2, 3])
  }

  func testSortedByKeyPathOrdersElements() {
    struct Item: Equatable { let rank: Int }
    let items = [Item(rank: 3), Item(rank: 1), Item(rank: 2)]
    XCTAssertEqual(
      items.fk_sorted(by: \.rank),
      [Item(rank: 1), Item(rank: 2), Item(rank: 3)]
    )
    XCTAssertEqual(
      items.fk_sorted(by: \.rank, ascending: false).map(\.rank),
      [3, 2, 1]
    )
  }

  func testRotatedLeftShiftsElements() {
    XCTAssertEqual([1, 2, 3, 4].fk_rotatedLeft(by: 1), [2, 3, 4, 1])
    XCTAssertEqual([1, 2, 3].fk_rotatedLeft(by: 0), [1, 2, 3])
  }
}
