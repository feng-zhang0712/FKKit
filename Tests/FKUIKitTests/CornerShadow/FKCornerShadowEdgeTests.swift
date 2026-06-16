import FKUIKit
import XCTest

final class FKCornerShadowEdgeTests: XCTestCase {
  func testAllContainsEveryEdge() {
    let all: FKCornerShadowEdge = [.top, .left, .bottom, .right]
    XCTAssertEqual(all, .all)
  }

  func testElevationDefaultsMatchProductionCardShadow() {
    let elevation = FKCornerShadowElevation()

    XCTAssertEqual(elevation.opacity, 0.14, accuracy: 0.001)
    XCTAssertEqual(elevation.blur, 12, accuracy: 0.001)
    XCTAssertEqual(elevation.edges, .all)
  }
}
