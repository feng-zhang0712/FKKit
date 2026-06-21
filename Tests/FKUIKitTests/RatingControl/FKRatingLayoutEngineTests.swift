@testable import FKUIKit
import XCTest

final class FKRatingLayoutEngineTests: XCTestCase {
  private func makeConfiguration(
    labelPlacement: FKRatingLabelPlacement = .none,
    itemCount: Int = 5
  ) -> FKRatingConfiguration {
    var configuration = FKRatingConfiguration()
    configuration.layout.labelPlacement = labelPlacement
    configuration.layout.itemCount = itemCount
    configuration.layout.itemSize = CGSize(width: 20, height: 20)
    configuration.layout.itemSpacing = 4
    return configuration
  }

  func testMetricsCentersIconsWhenLabelHidden() {
    let configuration = makeConfiguration()
    let bounds = CGRect(x: 0, y: 0, width: 200, height: 40)

    let metrics = FKRatingLayoutEngine.metrics(
      in: bounds,
      configuration: configuration,
      labelSize: .zero,
      layoutDirection: .leftToRight
    )

    XCTAssertEqual(metrics.itemFrames.count, 5)
    XCTAssertNil(metrics.labelFrame)
    XCTAssertEqual(metrics.iconsRect.midX, bounds.midX, accuracy: 1)
  }

  func testMetricsPlacesTrailingLabelBesideIcons() {
    var configuration = makeConfiguration(labelPlacement: .trailing)
    configuration.layout.labelSpacing = 8
    let labelSize = CGSize(width: 30, height: 16)

    let metrics = FKRatingLayoutEngine.metrics(
      in: CGRect(x: 0, y: 0, width: 200, height: 40),
      configuration: configuration,
      labelSize: labelSize,
      layoutDirection: .leftToRight
    )

    XCTAssertNotNil(metrics.labelFrame)
    XCTAssertEqual(metrics.labelFrame!.minX, metrics.iconsRect.maxX + 8, accuracy: 0.001)
  }

  func testMetricsPlacesBottomLabelBelowIcons() {
    var configuration = makeConfiguration(labelPlacement: .bottom)
    configuration.layout.labelSpacing = 6
    let labelSize = CGSize(width: 40, height: 14)

    let metrics = FKRatingLayoutEngine.metrics(
      in: CGRect(x: 0, y: 0, width: 200, height: 60),
      configuration: configuration,
      labelSize: labelSize,
      layoutDirection: .leftToRight
    )

    XCTAssertNotNil(metrics.labelFrame)
    XCTAssertEqual(metrics.labelFrame!.minY, metrics.iconsRect.maxY + 6, accuracy: 0.001)
  }

  func testMetricsReordersItemFramesForRightToLeftLayout() {
    let configuration = makeConfiguration(itemCount: 3)

    let metrics = FKRatingLayoutEngine.metrics(
      in: CGRect(x: 0, y: 0, width: 120, height: 40),
      configuration: configuration,
      labelSize: .zero,
      layoutDirection: .rightToLeft
    )

    XCTAssertEqual(metrics.itemFrames.count, 3)
    XCTAssertLessThan(metrics.itemFrames[0].midX, metrics.itemFrames[1].midX)
    XCTAssertLessThan(metrics.itemFrames[1].midX, metrics.itemFrames[2].midX)
  }

  func testIntrinsicContentSizeIncludesTrailingLabelWidth() {
    var configuration = makeConfiguration(labelPlacement: .trailing)
    configuration.layout.labelSpacing = 8
    let labelSize = CGSize(width: 24, height: 16)

    let size = FKRatingLayoutEngine.intrinsicContentSize(
      configuration: configuration,
      labelSize: labelSize
    )

    let iconsWidth: CGFloat = 5 * 20 + 4 * 4
    XCTAssertEqual(size.width, iconsWidth + 8 + 24, accuracy: 0.001)
  }

  func testValueMapsHorizontalPositionToRatingRange() {
    let configuration = makeConfiguration(itemCount: 5)
    let metrics = FKRatingLayoutEngine.metrics(
      in: CGRect(x: 0, y: 0, width: 120, height: 40),
      configuration: configuration,
      labelSize: .zero,
      layoutDirection: .leftToRight
    )

    let minimum: Double = 0
    let maximum: Double = 5
    let left = FKRatingLayoutEngine.value(
      at: CGPoint(x: metrics.iconsRect.minX, y: 0),
      in: metrics,
      minimumValue: minimum,
      maximumValue: maximum,
      layoutDirection: .leftToRight
    )
    let right = FKRatingLayoutEngine.value(
      at: CGPoint(x: metrics.iconsRect.maxX, y: 0),
      in: metrics,
      minimumValue: minimum,
      maximumValue: maximum,
      layoutDirection: .leftToRight
    )

    XCTAssertEqual(left, minimum, accuracy: 0.001)
    XCTAssertEqual(right, maximum, accuracy: 0.001)
  }

  func testExpandedHitFrameExpandsToMinimumTouchTarget() {
    let itemFrame = CGRect(x: 10, y: 10, width: 12, height: 12)
    let expanded = FKRatingLayoutEngine.expandedHitFrame(
      for: itemFrame,
      minimumSize: CGSize(width: 44, height: 44)
    )

    XCTAssertEqual(expanded.width, 44, accuracy: 0.001)
    XCTAssertEqual(expanded.height, 44, accuracy: 0.001)
    XCTAssertEqual(expanded.midX, itemFrame.midX, accuracy: 0.001)
  }

  func testFillFractionClampsPerItemSpan() {
    XCTAssertEqual(
      FKRatingLayoutEngine.fillFraction(
        forItemAt: 0,
        value: 0.5,
        minimumValue: 0,
        maximumValue: 5,
        itemCount: 5
      ),
      0.5,
      accuracy: 0.001
    )
    XCTAssertEqual(
      FKRatingLayoutEngine.fillFraction(
        forItemAt: 0,
        value: -1,
        minimumValue: 0,
        maximumValue: 5,
        itemCount: 5
      ),
      0,
      accuracy: 0.001
    )
    XCTAssertEqual(
      FKRatingLayoutEngine.fillFraction(
        forItemAt: 0,
        value: 10,
        minimumValue: 0,
        maximumValue: 5,
        itemCount: 5
      ),
      1,
      accuracy: 0.001
    )
  }
}
