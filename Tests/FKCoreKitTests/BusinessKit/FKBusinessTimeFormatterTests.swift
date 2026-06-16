import FKCoreKit
import XCTest

final class FKBusinessTimeFormatterTests: XCTestCase {
  private let formatter = FKBusinessTimeFormatter(languageCodeProvider: { "en_US_POSIX" })

  func testFormatUsesPatternAndLocale() {
    let date = Date(timeIntervalSince1970: 0)
    let formatted = formatter.format(date: date, format: "yyyy", locale: Locale(identifier: "en_US_POSIX"))

    XCTAssertEqual(formatted, "1970")
  }

  func testRelativeDescriptionUsesJustNowForRecentPast() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let recent = now.addingTimeInterval(-15)
    let description = formatter.relativeDescription(from: recent, now: now)

    XCTAssertFalse(description.isEmpty)
    XCTAssertFalse(description.contains("1970"))
  }

  func testRelativeDescriptionFormatsFutureDatesAbsolutely() {
    let now = Date(timeIntervalSince1970: 0)
    let future = Date(timeIntervalSince1970: 4_102_444_800)
    let description = formatter.relativeDescription(from: future, now: now)

    XCTAssertTrue(description.contains("2100"))
  }
}
