import CoreGraphics
import FKCoreKit
import XCTest

final class CGPointExtensionTests: XCTestCase {
  func testDistanceUsesEuclideanFormula() {
    let origin = CGPoint.zero
    let point = CGPoint(x: 3, y: 4)

    XCTAssertEqual(origin.fk_distance(to: point), 5, accuracy: 0.001)
  }

  func testAddAndSubtractCombineComponents() {
    let lhs = CGPoint(x: 1, y: 2)
    let rhs = CGPoint(x: 4, y: 5)

    XCTAssertEqual(CGPoint.fk_add(lhs, rhs), CGPoint(x: 5, y: 7))
    XCTAssertEqual(CGPoint.fk_subtract(rhs, lhs), CGPoint(x: 3, y: 3))
  }

  func testScaledMultipliesBothAxes() {
    XCTAssertEqual(CGPoint(x: 2, y: 3).fk_scaled(by: 2), CGPoint(x: 4, y: 6))
  }
}
