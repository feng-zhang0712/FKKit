import FKCoreKit
import XCTest

final class ComparableExtensionTests: XCTestCase {
  func testClampedKeepsValueInsideClosedRange() {
    XCTAssertEqual(5.fk_clamped(to: 0...10), 5)
    XCTAssertEqual((-2).fk_clamped(to: 0...10), 0)
    XCTAssertEqual(12.fk_clamped(to: 0...10), 10)
  }

  func testClampedSwapsInvertedMinAndMaxBounds() {
    XCTAssertEqual(5.fk_clamped(min: 10, max: 0), 5)
    XCTAssertEqual(15.fk_clamped(min: 10, max: 0), 10)
  }
}
