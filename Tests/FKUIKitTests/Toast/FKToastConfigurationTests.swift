import FKUIKit
import XCTest

final class FKToastConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesToastKindAndNormalPriority() {
    let config = FKToastConfiguration()
    XCTAssertEqual(config.kind, .toast)
    XCTAssertEqual(config.style, .normal)
    XCTAssertEqual(config.priority, .normal)
    XCTAssertEqual(config.duration, 2, accuracy: 0.001)
  }

  func testQueueConfigurationClampsConcurrentDisplayCountToAtLeastOne() {
    let queue = FKToastQueueConfiguration(maxConcurrentDisplayCount: 0)
    XCTAssertEqual(queue.maxConcurrentDisplayCount, 1)
  }

  func testQueueConfigurationClampsNegativeDeduplicationWindowToZero() {
    let queue = FKToastQueueConfiguration(deduplicationWindow: -5)
    XCTAssertEqual(queue.deduplicationWindow, 0, accuracy: 0.001)
  }

  func testConfigurationClampsMaxWidthRatioIntoValidRange() {
    let narrow = FKToastConfiguration(maxWidthRatio: 0.1)
    let wide = FKToastConfiguration(maxWidthRatio: 2)

    XCTAssertEqual(narrow.maxWidthRatio, 0.4, accuracy: 0.001)
    XCTAssertEqual(wide.maxWidthRatio, 1, accuracy: 0.001)
  }

  func testToastActionEquatableUsesTitleAndColor() {
    let first = FKToastAction(title: "Retry", titleColor: .white)
    let second = FKToastAction(title: "Retry", titleColor: .white)
    let different = FKToastAction(title: "Dismiss", titleColor: .white)

    XCTAssertEqual(first, second)
    XCTAssertNotEqual(first, different)
  }
}
