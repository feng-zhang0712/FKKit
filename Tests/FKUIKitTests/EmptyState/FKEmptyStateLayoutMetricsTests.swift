@testable import FKUIKit
import XCTest

final class FKEmptyStateLayoutMetricsTests: XCTestCase {
  func testSpacingScalesWithDensity() {
    let compact = FKEmptyStateLayoutMetrics(density: .compact)
    let regular = FKEmptyStateLayoutMetrics(density: .regular)
    let comfortable = FKEmptyStateLayoutMetrics(density: .comfortable)

    let base: CGFloat = 16
    XCTAssertEqual(compact.spacing(from: base), 12, accuracy: 0.001)
    XCTAssertEqual(regular.spacing(from: base), 16, accuracy: 0.001)
    XCTAssertEqual(comfortable.spacing(from: base), 20, accuracy: 0.001)
  }

  func testSegmentSpacingPrefersExplicitOverride() {
    let metrics = FKEmptyStateLayoutMetrics(density: .compact)

    XCTAssertEqual(metrics.segmentSpacing(24, fallback: 16), 24, accuracy: 0.001)
    XCTAssertEqual(metrics.segmentSpacing(nil, fallback: 16), 12, accuracy: 0.001)
  }

  func testImageSizeScalesWithDensity() {
    let base = CGSize(width: 120, height: 120)
    let compact = FKEmptyStateLayoutMetrics(density: .compact).imageSize(from: base)
    let comfortable = FKEmptyStateLayoutMetrics(density: .comfortable).imageSize(from: base)

    XCTAssertEqual(compact.width, 102, accuracy: 0.001)
    XCTAssertEqual(comfortable.width, 132, accuracy: 0.001)
  }

  func testHorizontalRowSpacingNeverDropsBelowCompactMinimum() {
    let metrics = FKEmptyStateLayoutMetrics(density: .compact)
    XCTAssertEqual(metrics.horizontalRowSpacing(from: 4), 8, accuracy: 0.001)
  }
}
