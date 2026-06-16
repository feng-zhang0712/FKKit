import CoreGraphics
import FKCoreKit
import XCTest

final class CGSizeExtensionTests: XCTestCase {
  func testAreaAndAspectRatioHelpers() {
    let size = CGSize(width: 200, height: 100)

    XCTAssertEqual(size.fk_area, 20_000, accuracy: 0.001)
    XCTAssertEqual(size.fk_aspectRatio, 2, accuracy: 0.001)
    XCTAssertEqual(CGSize(width: 10, height: 0).fk_aspectRatio, 0, accuracy: 0.001)
  }

  func testInsetByClampsDimensionsAtZero() {
    let inset = CGSize(width: 20, height: 20).fk_insetBy(top: 5, left: 15, bottom: 5, right: 15)

    XCTAssertEqual(inset.width, 0, accuracy: 0.001)
    XCTAssertEqual(inset.height, 10, accuracy: 0.001)
  }
}
