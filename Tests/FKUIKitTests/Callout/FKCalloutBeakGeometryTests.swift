@testable import FKUIKit
import UIKit
import XCTest

final class FKCalloutBeakGeometryTests: XCTestCase {
  private let bounds = CGRect(x: 0, y: 0, width: 200, height: 120)

  private func makeMetrics(
    beakEdge: FKCalloutPlacement.BeakEdge = .top,
    center: CGFloat = 100,
    width: CGFloat = 24,
    height: CGFloat = 12
  ) -> FKCalloutBeakGeometry.LayoutMetrics {
    FKCalloutBeakGeometry.LayoutMetrics(
      beakEdge: beakEdge,
      beakCenterAlongEdge: center,
      beakWidth: width,
      beakHeight: height,
      cornerRadius: 8
    )
  }

  func testBodyPathInsetsTopEdgeByBeakHeight() {
    let metrics = makeMetrics(beakEdge: .top, height: 10)
    let body = FKCalloutBeakGeometry.bodyPath(bounds: bounds, metrics: metrics)

    XCTAssertEqual(body.bounds.minY, 10, accuracy: 0.001)
    XCTAssertEqual(body.bounds.height, bounds.height - 10, accuracy: 0.001)
  }

  func testBeakFrameForTopEdgeCentersHorizontally() {
    let metrics = makeMetrics(beakEdge: .top, center: 100, width: 20, height: 8)
    let frame = FKCalloutBeakGeometry.beakFrame(bounds: bounds, metrics: metrics)

    XCTAssertEqual(frame.midX, 100, accuracy: 0.001)
    XCTAssertEqual(frame.minY, 0, accuracy: 0.001)
    XCTAssertEqual(frame.height, 8, accuracy: 0.001)
  }

  func testBeakFrameForBottomEdgeAnchorsToMaxY() {
    let metrics = makeMetrics(beakEdge: .bottom, center: 80, width: 16, height: 10)
    let frame = FKCalloutBeakGeometry.beakFrame(bounds: bounds, metrics: metrics)

    XCTAssertEqual(frame.maxY, bounds.maxY, accuracy: 0.001)
  }

  func testContentLayoutGuideInsetsAddsBeakHeightToTopEdge() {
    let metrics = makeMetrics(beakEdge: .top, height: 12)
    let insets = FKCalloutBeakGeometry.contentLayoutGuideInsets(
      bubbleBounds: bounds,
      metrics: metrics,
      contentInsets: .init(top: 8, leading: 12, bottom: 8, trailing: 12)
    )

    XCTAssertEqual(insets.top, 20, accuracy: 0.001)
    XCTAssertEqual(insets.left, 12, accuracy: 0.001)
  }

  func testContentLayoutGuideInsetsAddsBeakHeightToTrailingEdge() {
    let metrics = makeMetrics(beakEdge: .trailing, height: 10)
    let insets = FKCalloutBeakGeometry.contentLayoutGuideInsets(
      bubbleBounds: bounds,
      metrics: metrics,
      contentInsets: .init(top: 4, leading: 6, bottom: 4, trailing: 6)
    )

    XCTAssertEqual(insets.right, 16, accuracy: 0.001)
  }

  func testIsoscelesBeakPathIsClosedTriangle() {
    let path = FKCalloutBeakGeometry.beakPath(bounds: bounds, metrics: makeMetrics())

    XCTAssertTrue(path.isEmpty == false)
    XCTAssertEqual(path.currentPoint.y, path.cgPath.boundingBox.maxY, accuracy: 0.001)
  }

  func testEquilateralStyleIncreasesBeakHeight() {
    var isosceles = makeMetrics(width: 20, height: 10)
    isosceles.beakStyle = .isosceles
    var equilateral = makeMetrics(width: 20, height: 10)
    equilateral.beakStyle = .equilateral

    let isoPath = FKCalloutBeakGeometry.beakPath(bounds: bounds, metrics: isosceles)
    let equiPath = FKCalloutBeakGeometry.beakPath(bounds: bounds, metrics: equilateral)

    XCTAssertGreaterThan(equiPath.bounds.height, isoPath.bounds.height)
  }

  func testUnifiedBubblePathIncludesBeakWhenRequested() {
    let withBeak = FKCalloutBeakGeometry.unifiedBubblePath(
      bounds: bounds,
      metrics: makeMetrics(),
      includesBeak: true
    )
    let withoutBeak = FKCalloutBeakGeometry.unifiedBubblePath(
      bounds: bounds,
      metrics: makeMetrics(),
      includesBeak: false
    )

    XCTAssertGreaterThan(withBeak.boundingBox.height, withoutBeak.boundingBox.height)
  }
}
