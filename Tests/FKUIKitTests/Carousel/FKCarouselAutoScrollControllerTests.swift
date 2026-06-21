@testable import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKCarouselAutoScrollControllerTests: FKUIKitTestCase {
  private var controller: FKCarouselAutoScrollController!

  override func setUp() {
    super.setUp()
    controller = FKCarouselAutoScrollController()
    controller.configuration.isEnabled = true
    controller.configuration.interval = 0.1
    controller.pageCount = 3
    controller.currentPageIndex = 0
    controller.isVisible = true
    controller.isAppActive = true
    controller.isUserInteracting = false
  }

  override func tearDown() {
    controller.invalidateTimer()
    controller = nil
    super.tearDown()
  }

  private func waitForPotentialAdvance(timeout: TimeInterval = 0.3) {
    let expectation = expectation(description: "wait")
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: timeout + 0.5)
  }

  func testAutoScrollDoesNotAdvanceWhenDisabled() {
    var advances: [(Int, Int)] = []
    controller.onAdvance = { from, to in
      advances.append((from, to))
      return true
    }
    controller.configuration.isEnabled = false
    controller.refreshTimerState()

    waitForPotentialAdvance()

    XCTAssertTrue(advances.isEmpty)
  }

  func testAutoScrollDoesNotAdvanceForSinglePageCarousel() {
    var advances: [(Int, Int)] = []
    controller.onAdvance = { from, to in
      advances.append((from, to))
      return true
    }
    controller.pageCount = 1
    controller.refreshTimerState()

    waitForPotentialAdvance()

    XCTAssertTrue(advances.isEmpty)
  }

  func testAutoScrollPausesWhenUserIsInteracting() {
    var advances: [(Int, Int)] = []
    controller.onAdvance = { from, to in
      advances.append((from, to))
      return true
    }
    controller.configuration.pausesOnUserInteraction = true
    controller.isUserInteracting = true
    controller.refreshTimerState()

    waitForPotentialAdvance()

    XCTAssertTrue(advances.isEmpty)
  }

  func testAutoScrollPausesWhenOffscreen() {
    var advances: [(Int, Int)] = []
    controller.onAdvance = { from, to in
      advances.append((from, to))
      return true
    }
    controller.configuration.pausesWhenOffscreen = true
    controller.isVisible = false
    controller.refreshTimerState()

    waitForPotentialAdvance()

    XCTAssertTrue(advances.isEmpty)
  }

  func testInvalidateTimerStopsFurtherAdvances() {
    var advances: [(Int, Int)] = []
    controller.onAdvance = { from, to in
      advances.append((from, to))
      return true
    }
    controller.refreshTimerState()
    waitForPotentialAdvance(timeout: 0.15)
    let countAfterFirstWindow = advances.count

    controller.invalidateTimer()
    waitForPotentialAdvance()

    XCTAssertEqual(advances.count, countAfterFirstWindow)
  }

  func testResetIntervalAfterManualChangeContinuesAdvancing() {
    var advances: [(Int, Int)] = []
    controller.onAdvance = { [self] from, to in
      advances.append((from, to))
      controller.currentPageIndex = to
      return true
    }
    controller.refreshTimerState()
    waitForPotentialAdvance(timeout: 0.15)
    controller.resetIntervalAfterManualChange()
    waitForPotentialAdvance()

    XCTAssertGreaterThanOrEqual(advances.count, 1)
  }

  func testTimerAdvanceCallsOnAdvanceHandler() {
    var advances: [(Int, Int)] = []
    controller.onAdvance = { from, to in
      advances.append((from, to))
      return true
    }
    controller.refreshTimerState()

    waitForPotentialAdvance()

    XCTAssertFalse(advances.isEmpty)
    XCTAssertEqual(advances.first?.0, 0)
    XCTAssertEqual(advances.first?.1, 1)
  }
}
