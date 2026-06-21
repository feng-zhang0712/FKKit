@testable import FKUIKit
import XCTest

final class FKDividerGeometryTests: XCTestCase {
  func testHorizontalSegmentRespectsContentInsets() {
    let bounds = CGRect(x: 0, y: 0, width: 100, height: 2)
    let insets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 8)

    let segment = FKDividerGeometry.horizontalSegment(in: bounds, contentInsets: insets)

    XCTAssertNotNil(segment)
    XCTAssertEqual(segment!.x1, 12, accuracy: 0.001)
    XCTAssertEqual(segment!.x2, 92, accuracy: 0.001)
    XCTAssertEqual(segment!.y, 1, accuracy: 0.001)
  }

  func testHorizontalSegmentReturnsNilWhenSegmentCollapses() {
    let bounds = CGRect(x: 0, y: 0, width: 10, height: 1)
    let insets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)

    XCTAssertNil(FKDividerGeometry.horizontalSegment(in: bounds, contentInsets: insets))
  }

  func testVerticalSegmentRespectsContentInsets() {
    let bounds = CGRect(x: 0, y: 0, width: 2, height: 80)
    let insets = UIEdgeInsets(top: 10, left: 0, bottom: 15, right: 0)

    let segment = FKDividerGeometry.verticalSegment(in: bounds, contentInsets: insets)

    XCTAssertNotNil(segment)
    XCTAssertEqual(segment!.x, 1, accuracy: 0.001)
    XCTAssertEqual(segment!.y1, 10, accuracy: 0.001)
    XCTAssertEqual(segment!.y2, 65, accuracy: 0.001)
  }

  func testVerticalSegmentReturnsNilWhenSegmentCollapses() {
    let bounds = CGRect(x: 0, y: 0, width: 1, height: 8)
    let insets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)

    XCTAssertNil(FKDividerGeometry.verticalSegment(in: bounds, contentInsets: insets))
  }
}
