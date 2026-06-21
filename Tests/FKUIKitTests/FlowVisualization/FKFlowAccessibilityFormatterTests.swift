@testable import FKUIKit
import XCTest

final class FKFlowAccessibilityFormatterTests: XCTestCase {
  func testStepLabelInterpolateDefaultFormat() {
    let item = FKFlowStepItem(
      id: "checkout",
      title: "Payment",
      subtitle: "Card ending 4242",
      state: .current
    )
    let configuration = FKFlowAccessibilityConfiguration()

    let label = FKFlowAccessibilityFormatter.stepLabel(
      index: 1,
      count: 3,
      item: item,
      configuration: configuration
    )

    XCTAssertEqual(label, "Step 2 of 3, Payment, Card ending 4242, Current step")
  }

  func testTimelineLabelIncludesTimestampAndCaption() {
    let item = FKFlowStepItem(
      id: "shipped",
      title: "Shipped",
      subtitle: "Carrier picked up",
      caption: "Left warehouse",
      state: .completed
    )
    var configuration = FKFlowAccessibilityConfiguration()
    configuration.timelineLabelFormat = "{title} at {timestamp}. {caption}. {state}"

    let label = FKFlowAccessibilityFormatter.timelineLabel(
      item: item,
      timestamp: "Jun 21, 10:30 AM",
      configuration: configuration
    )

    XCTAssertEqual(
      label,
      "Shipped, Carrier picked up at Jun 21, 10:30 AM. Left warehouse. Completed"
    )
  }

  func testTimelineLabelUsesEmptyTimestampWhenMissing() {
    let item = FKFlowStepItem(id: "pending", title: "Pending", state: .upcoming)
    let configuration = FKFlowAccessibilityConfiguration()

    let label = FKFlowAccessibilityFormatter.timelineLabel(
      item: item,
      timestamp: nil,
      configuration: configuration
    )

    XCTAssertEqual(label, "Pending, , , Upcoming")
  }

  func testLocalizedStateMapsAllCases() {
    XCTAssertEqual(FKFlowAccessibilityFormatter.localizedState(.completed), "Completed")
    XCTAssertEqual(FKFlowAccessibilityFormatter.localizedState(.current), "Current step")
    XCTAssertEqual(FKFlowAccessibilityFormatter.localizedState(.upcoming), "Upcoming")
    XCTAssertEqual(FKFlowAccessibilityFormatter.localizedState(.error), "Error")
    XCTAssertEqual(FKFlowAccessibilityFormatter.localizedState(.skipped), "Skipped")
    XCTAssertEqual(FKFlowAccessibilityFormatter.localizedState(.disabled), "Disabled")
  }
}
