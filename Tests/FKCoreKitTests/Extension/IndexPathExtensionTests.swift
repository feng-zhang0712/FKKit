import FKCoreKit
import XCTest

final class IndexPathExtensionTests: XCTestCase {
  func testZeroReturnsFirstRowInFirstSection() {
    XCTAssertEqual(IndexPath.fk_zero, IndexPath(row: 0, section: 0))
    XCTAssertTrue(IndexPath.fk_zero.fk_isFirstRow)
  }

  func testIsFirstRowRequiresSectionAndRowZero() {
    XCTAssertFalse(IndexPath(row: 1, section: 0).fk_isFirstRow)
    XCTAssertFalse(IndexPath(row: 0, section: 1).fk_isFirstRow)
  }
}
