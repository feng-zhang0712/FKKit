import FKUIKit
import XCTest

final class FKFlowProgressResolverTests: XCTestCase {
  func testActiveIndexPrefersCurrentOverUpcomingAndCompleted() {
    let items = [
      FKFlowStepItem(id: "1", title: "Done", state: .completed),
      FKFlowStepItem(id: "2", title: "Now", state: .current),
      FKFlowStepItem(id: "3", title: "Next", state: .upcoming),
    ]

    XCTAssertEqual(FKFlowProgressResolver.activeIndex(in: items), 1)
  }

  func testActiveIndexFallsBackToFirstUpcoming() {
    let items = [
      FKFlowStepItem(id: "1", title: "Done", state: .completed),
      FKFlowStepItem(id: "2", title: "Next", state: .upcoming),
    ]

    XCTAssertEqual(FKFlowProgressResolver.activeIndex(in: items), 1)
  }

  func testActiveIndexFallsBackToLastCompletedWhenNoCurrentOrUpcoming() {
    let items = [
      FKFlowStepItem(id: "1", title: "First", state: .completed),
      FKFlowStepItem(id: "2", title: "Second", state: .completed),
    ]

    XCTAssertEqual(FKFlowProgressResolver.activeIndex(in: items), 1)
  }

  func testActiveIndexReturnsNilForEmptyItems() {
    XCTAssertNil(FKFlowProgressResolver.activeIndex(in: []))
  }
}
