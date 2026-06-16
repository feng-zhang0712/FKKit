import FKUIKit
import XCTest

final class FKExpandableTextStateTests: XCTestCase {
  func testCollapsedAndExpandedAreDistinctAndEquatable() {
    XCTAssertEqual(FKExpandableTextState.collapsed, .collapsed)
    XCTAssertEqual(FKExpandableTextState.expanded, .expanded)
    XCTAssertNotEqual(FKExpandableTextState.collapsed, .expanded)
  }
}
