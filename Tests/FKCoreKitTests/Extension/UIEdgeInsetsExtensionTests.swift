import FKCoreKit
import UIKit
import XCTest

final class UIEdgeInsetsExtensionTests: XCTestCase {
  func testAllHorizontalAndVerticalFactoriesBuildExpectedInsets() {
    XCTAssertEqual(UIEdgeInsets.fk_all(8), UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
    XCTAssertEqual(UIEdgeInsets.fk_horizontal(12), UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
    XCTAssertEqual(UIEdgeInsets.fk_vertical(6), UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0))
  }

  func testHorizontalAndVerticalTotalsSumEdgeInsets() {
    let insets = UIEdgeInsets(top: 4, left: 10, bottom: 6, right: 14)

    XCTAssertEqual(insets.fk_horizontalTotal, 24, accuracy: 0.001)
    XCTAssertEqual(insets.fk_verticalTotal, 10, accuracy: 0.001)
  }

  func testInsetAddsInsetsComponentWise() {
    let base = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
    let extra = UIEdgeInsets(top: 5, left: 6, bottom: 7, right: 8)

    XCTAssertEqual(base.fk_inset(by: extra), UIEdgeInsets(top: 6, left: 8, bottom: 10, right: 12))
  }
}
