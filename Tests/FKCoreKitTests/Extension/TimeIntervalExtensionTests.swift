import FKCoreKit
import XCTest

final class TimeIntervalExtensionTests: XCTestCase {
  func testWholeMinutesAndHoursTruncateTowardZero() {
    XCTAssertEqual(TimeInterval(125).fk_wholeMinutes, 2)
    XCTAssertEqual(TimeInterval(7_200).fk_wholeHours, 2)
    XCTAssertEqual(TimeInterval(-125).fk_wholeMinutes, -2)
  }

  func testMillisecondsConversionIsSymmetric() {
    let interval: TimeInterval = 1.5

    XCTAssertEqual(interval.fk_milliseconds, 1_500, accuracy: 0.001)
    XCTAssertEqual(TimeInterval.fk_fromMilliseconds(250), 0.25, accuracy: 0.001)
  }
}
