import CoreGraphics
import FKCoreKit
import XCTest

final class CGFloatExtensionTests: XCTestCase {
  func testRoundedToPixelSnapsToNearestPixelBoundary() {
    XCTAssertEqual(CGFloat(10.333).fk_roundedToPixel(scale: 3), 10.333, accuracy: 0.001)
    XCTAssertEqual(CGFloat(10.4).fk_roundedToPixel(scale: 2), 10.5, accuracy: 0.001)
  }

  func testDegreeAndRadianConversionIsSymmetric() {
    let radians = CGFloat.fk_degreesToRadians(180)
    XCTAssertEqual(radians, .pi, accuracy: 0.001)
    XCTAssertEqual(CGFloat.fk_radiansToDegrees(.pi), 180, accuracy: 0.001)
  }
}
