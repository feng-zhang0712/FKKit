@testable import FKUIKit
import XCTest

final class FKFlowLayoutMetricsTests: XCTestCase {
  func testNodeDiameterReturnsBaseWithoutTraitCollection() {
    XCTAssertEqual(FKFlowLayoutMetrics.nodeDiameter(base: .small, scalesWithContentSize: true, traitCollection: nil), 20)
    XCTAssertEqual(FKFlowLayoutMetrics.nodeDiameter(base: .medium, scalesWithContentSize: true, traitCollection: nil), 28)
    XCTAssertEqual(FKFlowLayoutMetrics.nodeDiameter(base: .large, scalesWithContentSize: true, traitCollection: nil), 36)
  }

  func testNodeDiameterScalesForAccessibilityContentSize() {
    let traits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

    let scaled = FKFlowLayoutMetrics.nodeDiameter(
      base: .medium,
      scalesWithContentSize: true,
      traitCollection: traits
    )

    XCTAssertEqual(scaled, 28 * 1.12, accuracy: 0.001)
  }

  func testNodeDiameterIgnoresScalingWhenDisabled() {
    let traits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

    let diameter = FKFlowLayoutMetrics.nodeDiameter(
      base: .medium,
      scalesWithContentSize: false,
      traitCollection: traits
    )

    XCTAssertEqual(diameter, 28, accuracy: 0.001)
  }

  func testDensitySpacingReturnsAxisSpecificValues() {
    XCTAssertEqual(FKFlowLayoutMetrics.densitySpacing(.regular, axis: .horizontal), 12)
    XCTAssertEqual(FKFlowLayoutMetrics.densitySpacing(.compact, axis: .horizontal), 8)
    XCTAssertEqual(FKFlowLayoutMetrics.densitySpacing(.spacious, axis: .vertical), 24)
  }

  func testLabelSpacingMatchesDensityPreset() {
    XCTAssertEqual(FKFlowLayoutMetrics.labelSpacing(.regular), 6)
    XCTAssertEqual(FKFlowLayoutMetrics.labelSpacing(.compact), 4)
    XCTAssertEqual(FKFlowLayoutMetrics.labelSpacing(.spacious), 10)
  }

  func testContentInsetsUseEmbeddedVariantWhenEmbedded() {
    let insets = FKFlowLayoutMetrics.contentInsets(for: .regular, embedded: true)

    XCTAssertEqual(insets.top, 4)
    XCTAssertEqual(insets.bottom, 4)
    XCTAssertEqual(insets.left, 0)
    XCTAssertEqual(insets.right, 0)
  }

  func testContentInsetsUseDensityPresetWhenNotEmbedded() {
    let compact = FKFlowLayoutMetrics.contentInsets(for: .compact, embedded: false)

    XCTAssertEqual(compact.top, 4)
    XCTAssertEqual(compact.left, 8)
    XCTAssertEqual(compact.right, 8)
    XCTAssertEqual(compact.bottom, 4)
  }
}
