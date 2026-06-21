@testable import FKUIKit
import XCTest

final class FKSheetDetentIndexResolverTests: XCTestCase {
  func testSmallestIndexReturnsFirstMatchingMinimumHeight() {
    let heights: [CGFloat] = [320, 240, 240, 400]

    XCTAssertEqual(FKSheetDetentIndexResolver.smallestIndex(in: heights), 1)
  }

  func testLargestIndexReturnsLastMatchingMaximumHeight() {
    let heights: [CGFloat] = [240, 400, 400, 320]

    XCTAssertEqual(FKSheetDetentIndexResolver.largestIndex(in: heights), 2)
  }

  func testNextTallerIndexFindsNextDistinctHeight() {
    let heights: [CGFloat] = [200, 320, 480]

    XCTAssertEqual(FKSheetDetentIndexResolver.nextTallerIndex(from: 0, in: heights), 1)
    XCTAssertEqual(FKSheetDetentIndexResolver.nextTallerIndex(from: 1, in: heights), 2)
  }

  func testNextShorterIndexFindsPreviousDistinctHeight() {
    let heights: [CGFloat] = [200, 320, 480]

    XCTAssertEqual(FKSheetDetentIndexResolver.nextShorterIndex(from: 2, in: heights), 1)
    XCTAssertEqual(FKSheetDetentIndexResolver.nextShorterIndex(from: 1, in: heights), 0)
  }

  func testNextTallerIndexStaysAtCurrentWhenAlreadyLargest() {
    let heights: [CGFloat] = [200, 320, 480]

    XCTAssertEqual(FKSheetDetentIndexResolver.nextTallerIndex(from: 2, in: heights), 2)
  }

  func testNextShorterIndexStaysAtCurrentWhenAlreadySmallest() {
    let heights: [CGFloat] = [200, 320, 480]

    XCTAssertEqual(FKSheetDetentIndexResolver.nextShorterIndex(from: 0, in: heights), 0)
  }

  func testEmptyHeightsReturnZeroIndex() {
    XCTAssertEqual(FKSheetDetentIndexResolver.smallestIndex(in: []), 0)
    XCTAssertEqual(FKSheetDetentIndexResolver.largestIndex(in: []), 0)
  }

  func testOutOfRangeCurrentIndexFallsBackToBoundaryIndex() {
    let heights: [CGFloat] = [200, 320, 480]

    XCTAssertEqual(FKSheetDetentIndexResolver.nextTallerIndex(from: 9, in: heights), 2)
    XCTAssertEqual(FKSheetDetentIndexResolver.nextShorterIndex(from: -1, in: heights), 0)
  }
}
