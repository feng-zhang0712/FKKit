import FKUIKit
import XCTest

final class FKThemeMetricsTests: XCTestCase {
  func testSpacingTokenReturnsConfiguredValues() {
    let metrics = FKThemeMetrics(
      spacingXXS: 2,
      spacingXS: 4,
      spacingS: 8,
      spacingM: 16,
      spacingL: 32,
      spacingXL: 64
    )

    XCTAssertEqual(metrics.spacing(.xxs), 2)
    XCTAssertEqual(metrics.spacing(.xs), 4)
    XCTAssertEqual(metrics.spacing(.s), 8)
    XCTAssertEqual(metrics.spacing(.m), 16)
    XCTAssertEqual(metrics.spacing(.l), 32)
    XCTAssertEqual(metrics.spacing(.xl), 64)
  }

  func testDefaultMinimumHitTargetMatchesHIGGuidance() {
    XCTAssertEqual(FKThemeMetrics().minimumHitTarget, 44, accuracy: 0.001)
  }
}
