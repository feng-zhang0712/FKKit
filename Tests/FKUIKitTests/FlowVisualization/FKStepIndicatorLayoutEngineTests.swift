@testable import FKUIKit
import XCTest

@MainActor
final class FKStepIndicatorLayoutEngineTests: XCTestCase {
  func testMetricsReturnsZeroContentSizeForEmptyItems() {
    let configuration = FKStepIndicatorConfiguration()
    let metrics = FKStepIndicatorLayoutEngine.metrics(
      items: [],
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: 320, height: 200),
      layoutDirection: .leftToRight,
      traitCollection: nil
    )

    XCTAssertTrue(metrics.stepMetrics.isEmpty)
    XCTAssertEqual(metrics.contentSize, .zero)
    XCTAssertFalse(metrics.needsHorizontalScroll)
  }

  func testHorizontalTopLabelsProducesOneMetricPerItem() {
    let items = [
      FKFlowStepItem(id: "1", title: "Cart", state: .completed),
      FKFlowStepItem(id: "2", title: "Pay", state: .current),
      FKFlowStepItem(id: "3", title: "Done", state: .upcoming),
    ]
    var configuration = FKStepIndicatorConfiguration()
    configuration.layout.layout = .horizontalTopLabels

    let metrics = FKStepIndicatorLayoutEngine.metrics(
      items: items,
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: 390, height: 120),
      layoutDirection: .leftToRight,
      traitCollection: nil
    )

    XCTAssertEqual(metrics.stepMetrics.count, 3)
    XCTAssertGreaterThan(metrics.contentSize.height, 0)
    XCTAssertGreaterThan(metrics.contentSize.width, 0)
    XCTAssertNotNil(metrics.stepMetrics[0].connectorStart)
    XCTAssertNil(metrics.stepMetrics[2].connectorEnd)
  }

  func testMaxVisibleStepsForcesHorizontalScroll() {
    let items = (1 ... 6).map {
      FKFlowStepItem(id: "\($0)", title: "Step \($0)", state: .upcoming)
    }
    var configuration = FKStepIndicatorConfiguration()
    configuration.layout.maxVisibleSteps = 4

    let metrics = FKStepIndicatorLayoutEngine.metrics(
      items: items,
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: 390, height: 120),
      layoutDirection: .leftToRight,
      traitCollection: nil
    )

    XCTAssertTrue(metrics.needsHorizontalScroll)
    XCTAssertGreaterThan(metrics.stepMetrics.count, configuration.layout.maxVisibleSteps)
  }

  func testRightToLeftLayoutReversesHorizontalOrdering() {
    let items = [
      FKFlowStepItem(id: "1", title: "First", state: .completed),
      FKFlowStepItem(id: "2", title: "Second", state: .current),
    ]
    let bounds = CGRect(x: 0, y: 0, width: 320, height: 120)
    let configuration = FKStepIndicatorConfiguration()

    let ltr = FKStepIndicatorLayoutEngine.metrics(
      items: items,
      configuration: configuration,
      bounds: bounds,
      layoutDirection: .leftToRight,
      traitCollection: nil
    )
    let rtl = FKStepIndicatorLayoutEngine.metrics(
      items: items,
      configuration: configuration,
      bounds: bounds,
      layoutDirection: .rightToLeft,
      traitCollection: nil
    )

    XCTAssertEqual(ltr.stepMetrics.count, rtl.stepMetrics.count)
    XCTAssertLessThan(
      ltr.stepMetrics[0].nodeFrame.midX,
      ltr.stepMetrics[1].nodeFrame.midX
    )
    XCTAssertGreaterThan(
      rtl.stepMetrics[0].nodeFrame.midX,
      rtl.stepMetrics[1].nodeFrame.midX
    )
  }
}
