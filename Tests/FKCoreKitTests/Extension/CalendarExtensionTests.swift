import FKCoreKit
import XCTest

final class CalendarExtensionTests: XCTestCase {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  func testNumberOfDaysReturnsSignedDifferenceBetweenMidnights() {
    let from = Date(timeIntervalSince1970: 0)
    let to = Date(timeIntervalSince1970: 86_400 * 3)

    XCTAssertEqual(calendar.fk_numberOfDays(from: from, to: to), 3)
    XCTAssertEqual(calendar.fk_numberOfDays(from: to, to: from), -3)
  }

  func testStartAndEndOfWeekBoundInclusiveInterval() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    guard let start = calendar.fk_startOfWeek(for: date),
          let end = calendar.fk_endOfWeek(for: date) else {
      XCTFail("Expected week interval")
      return
    }

    XCTAssertLessThan(start, end)
    XCTAssertTrue(date.fk_isBetween(start, and: end))
  }
}
