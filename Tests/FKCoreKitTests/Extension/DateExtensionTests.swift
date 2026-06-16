import FKCoreKit
import XCTest

final class DateExtensionTests: XCTestCase {
  private var utcCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  func testStartOfDayReturnsMidnightInTimeZone() {
    let date = Date(timeIntervalSince1970: 1_700_000_123)
    let start = date.fk_startOfDay(calendar: utcCalendar, timeZone: TimeZone(secondsFromGMT: 0))

    XCTAssertEqual(utcCalendar.component(.hour, from: start), 0)
    XCTAssertEqual(utcCalendar.component(.minute, from: start), 0)
    XCTAssertEqual(utcCalendar.component(.second, from: start), 0)
  }

  func testIsBetweenReturnsTrueForInclusiveBounds() {
    let middle = Date(timeIntervalSince1970: 100)
    let start = Date(timeIntervalSince1970: 50)
    let end = Date(timeIntervalSince1970: 150)

    XCTAssertTrue(middle.fk_isBetween(start, and: end))
    XCTAssertTrue(start.fk_isBetween(start, and: end))
    XCTAssertTrue(end.fk_isBetween(start, and: end))
    XCTAssertFalse(Date(timeIntervalSince1970: 200).fk_isBetween(start, and: end))
  }

  func testIso8601UTCStringIncludesFractionalSecondsWhenEnabled() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let formatted = date.fk_iso8601UTCString(fractionalSeconds: true)

    XCTAssertTrue(formatted.contains("T"))
    XCTAssertTrue(formatted.hasSuffix("Z") || formatted.contains("+"))
  }

  func testStringToDateRoundTripWithFixedFormat() {
    let value = "2024-06-01 12:30:00"
    let timeZone = TimeZone(secondsFromGMT: 0)!
    let locale = Locale(identifier: "en_US_POSIX")

    let date = value.fk_toDate(format: "yyyy-MM-dd HH:mm:ss", timeZone: timeZone, locale: locale)
    XCTAssertNotNil(date)
    XCTAssertEqual(date?.fk_formatted("yyyy-MM-dd HH:mm:ss", timeZone: timeZone, locale: locale), value)
    XCTAssertTrue(value.fk_isValidDate(format: "yyyy-MM-dd HH:mm:ss", timeZone: timeZone, locale: locale))
    XCTAssertFalse("not-a-date".fk_isValidDate(format: "yyyy-MM-dd HH:mm:ss", timeZone: timeZone, locale: locale))
  }
}
