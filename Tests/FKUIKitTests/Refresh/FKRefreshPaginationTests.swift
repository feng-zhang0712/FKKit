import FKUIKit
import XCTest

final class FKRefreshPaginationTests: XCTestCase {
  func testResetForNewRequestSetsPageToOne() {
    var pagination = FKRefreshPagination(startingPage: 3)
    pagination.resetForNewRequest()
    XCTAssertEqual(pagination.page, 1)
  }

  func testAdvanceIncrementsPage() {
    var pagination = FKRefreshPagination()
    pagination.advance()
    XCTAssertEqual(pagination.page, 2)
  }

  func testNextPageReturnsLastLoadedPagePlusOne() {
    var pagination = FKRefreshPagination()
    XCTAssertEqual(pagination.nextPage, 2)

    pagination.advance()
    XCTAssertEqual(pagination.page, 2)
    XCTAssertEqual(pagination.nextPage, 3)
  }

  func testStartingPageClampsToMinimumOne() {
    let pagination = FKRefreshPagination(startingPage: 0)
    XCTAssertEqual(pagination.page, 1)
  }
}
