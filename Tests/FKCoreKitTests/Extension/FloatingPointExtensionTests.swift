import FKCoreKit
import XCTest

final class FloatingPointExtensionTests: XCTestCase {
  func testClampedKeepsValueInsideClosedRange() {
    XCTAssertEqual(5.0.fk_clamped(to: 0...10), 5.0, accuracy: 0.001)
    XCTAssertEqual((-3.0).fk_clamped(to: 0...10), 0.0, accuracy: 0.001)
    XCTAssertEqual(12.0.fk_clamped(to: 0...10), 10.0, accuracy: 0.001)
  }

  func testLerpInterpolatesBetweenEndpoints() {
    XCTAssertEqual(Double.fk_lerp(0, 10, t: 0.25), 2.5, accuracy: 0.001)
  }

  func testRoundedToDecimalPlacesUsesStandardRounding() {
    XCTAssertEqual(1.234.fk_rounded(toDecimalPlaces: 2), 1.23, accuracy: 0.001)
    XCTAssertEqual(1.235.fk_rounded(toDecimalPlaces: 2), 1.24, accuracy: 0.001)
  }

  func testFiniteOrNilReturnsNilForNonFiniteValues() {
    XCTAssertNotNil(Double.fk_finiteOrNil(3.5))
    XCTAssertEqual(Double.fk_finiteOrNil(3.5)!, 3.5, accuracy: 0.001)
    XCTAssertNil(Double.fk_finiteOrNil(.infinity))
  }
}
