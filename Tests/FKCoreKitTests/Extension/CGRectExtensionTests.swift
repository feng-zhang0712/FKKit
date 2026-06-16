import CoreGraphics
import FKCoreKit
import XCTest

final class CGRectExtensionTests: XCTestCase {
  func testCenterAndPositiveAreaHelpers() {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 50)

    XCTAssertEqual(rect.fk_center.x, 50, accuracy: 0.001)
    XCTAssertEqual(rect.fk_center.y, 25, accuracy: 0.001)
    XCTAssertTrue(rect.fk_hasPositiveArea)
    XCTAssertFalse(CGRect.zero.fk_hasPositiveArea)
  }

  func testInsetAndOutsetAdjustBoundsSymmetrically() {
    let rect = CGRect(x: 10, y: 10, width: 80, height: 40)

    XCTAssertEqual(rect.fk_insetBy(5), CGRect(x: 15, y: 15, width: 70, height: 30))
    XCTAssertEqual(rect.fk_outsetBy(5), CGRect(x: 5, y: 5, width: 90, height: 50))
  }
}
