import FKUIKit
import XCTest

final class FKQRCodeOverlayStyleTests: XCTestCase {
  func testDefaultMatchesDocumentedConstants() {
    let style = FKQRCodeOverlayStyle.default

    XCTAssertEqual(style.scanRegionRelativeSize, 0.68, accuracy: 0.001)
    XCTAssertEqual(style.cornerLength, 22, accuracy: 0.001)
    XCTAssertEqual(style.cornerLineWidth, 4, accuracy: 0.001)
    XCTAssertTrue(style.showsScanLineAnimation)
  }

  func testCustomInitializerPreservesFields() {
    let style = FKQRCodeOverlayStyle(
      scanRegionRelativeSize: 0.5,
      cornerLength: 18,
      cornerLineWidth: 2,
      showsScanLineAnimation: false
    )

    XCTAssertEqual(style, FKQRCodeOverlayStyle(
      scanRegionRelativeSize: 0.5,
      cornerLength: 18,
      cornerLineWidth: 2,
      showsScanLineAnimation: false
    ))
  }
}
