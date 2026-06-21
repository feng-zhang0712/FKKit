@testable import FKUIKit
import XCTest

@MainActor
final class FKTimelineLayoutEngineTests: XCTestCase {
  func testMetricsReturnsZeroHeightForEmptySections() {
    let configuration = FKTimelineConfiguration()

    let metrics = FKTimelineLayoutEngine.metrics(
      sections: [],
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: 320, height: 600),
      layoutDirection: .leftToRight,
      traitCollection: nil,
      expandedItemIDs: []
    )

    XCTAssertTrue(metrics.sections.isEmpty)
    let insets = configuration.layout.contentInsets
    XCTAssertEqual(metrics.contentSize.height, insets.top + insets.bottom, accuracy: 0.001)
  }

  func testMetricsProducesRowPerItemWithLeadingRail() {
    let section = FKTimelineSection(
      id: "today",
      title: "Today",
      items: [
        FKFlowStepItem(id: "a", title: "Shipped", subtitle: "Carrier picked up", state: .completed),
        FKFlowStepItem(id: "b", title: "Delivered", state: .current),
      ]
    )
    let configuration = FKTimelineConfiguration()

    let metrics = FKTimelineLayoutEngine.metrics(
      sections: [section],
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: 390, height: 800),
      layoutDirection: .leftToRight,
      traitCollection: nil,
      expandedItemIDs: []
    )

    XCTAssertEqual(metrics.sections.count, 1)
    XCTAssertEqual(metrics.sections[0].rows.count, 2)
    XCTAssertNotNil(metrics.sections[0].titleFrame)
    XCTAssertGreaterThan(metrics.sections[0].rows[0].nodeFrame.minX, 0)
    XCTAssertGreaterThan(
      metrics.sections[0].rows[0].titleFrame.minX,
      metrics.sections[0].rows[0].nodeFrame.maxX
    )
  }

  func testExpandedCaptionAddsCaptionFrame() {
    let item = FKFlowStepItem(
      id: "detail",
      title: "Review",
      caption: "Additional audit notes for this event.",
      state: .current
    )
    let section = FKTimelineSection(id: "s", title: "", items: [item])
    let configuration = FKTimelineConfiguration()

    let collapsed = FKTimelineLayoutEngine.metrics(
      sections: [section],
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: 390, height: 800),
      layoutDirection: .leftToRight,
      traitCollection: nil,
      expandedItemIDs: []
    )
    let expanded = FKTimelineLayoutEngine.metrics(
      sections: [section],
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: 390, height: 800),
      layoutDirection: .leftToRight,
      traitCollection: nil,
      expandedItemIDs: ["detail"]
    )

    XCTAssertNil(collapsed.sections[0].rows[0].captionFrame)
    XCTAssertNotNil(expanded.sections[0].rows[0].captionFrame)
    XCTAssertGreaterThan(expanded.contentSize.height, collapsed.contentSize.height)
  }

  func testTailStyleNoneOmitsConnectorOnFinalRow() {
    let section = FKTimelineSection(
      id: "s",
      title: "",
      items: [FKFlowStepItem(id: "only", title: "Only row", state: .current)]
    )
    var configuration = FKTimelineConfiguration()
    configuration.layout.tailStyle = .none

    let metrics = FKTimelineLayoutEngine.metrics(
      sections: [section],
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: 390, height: 400),
      layoutDirection: .leftToRight,
      traitCollection: nil,
      expandedItemIDs: []
    )

    XCTAssertNil(metrics.sections[0].rows[0].connectorFrame)
  }

  func testTimestampFramePresentWhenStyleIsAbsoluteAndDateProvided() {
    let item = FKFlowStepItem(
      id: "shipped",
      title: "Shipped",
      timestamp: Date(timeIntervalSince1970: 1_700_000_000),
      state: .completed
    )
    let section = FKTimelineSection(id: "s", title: "", items: [item])
    var configuration = FKTimelineConfiguration()
    configuration.layout.timestampStyle = .absolute

    let metrics = FKTimelineLayoutEngine.metrics(
      sections: [section],
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: 390, height: 400),
      layoutDirection: .leftToRight,
      traitCollection: nil,
      expandedItemIDs: []
    )

    XCTAssertNotNil(metrics.sections[0].rows[0].timestampFrame)
  }

  func testTimestampFrameOmittedWhenStyleIsHidden() {
    let item = FKFlowStepItem(
      id: "shipped",
      title: "Shipped",
      timestamp: Date(timeIntervalSince1970: 1_700_000_000),
      state: .completed
    )
    let section = FKTimelineSection(id: "s", title: "", items: [item])
    var configuration = FKTimelineConfiguration()
    configuration.layout.timestampStyle = .hidden

    let metrics = FKTimelineLayoutEngine.metrics(
      sections: [section],
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: 390, height: 400),
      layoutDirection: .leftToRight,
      traitCollection: nil,
      expandedItemIDs: []
    )

    XCTAssertNil(metrics.sections[0].rows[0].timestampFrame)
  }
}
