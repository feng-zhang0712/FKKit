@testable import FKUIKit
import XCTest

final class FKTimelineTimestampFormatterTests: XCTestCase {
  private func makeItem(
    timestamp: Date? = nil,
    formattedTimestamp: String? = nil
  ) -> FKFlowStepItem {
    FKFlowStepItem(
      id: "step",
      title: "Shipped",
      timestamp: timestamp,
      formattedTimestamp: formattedTimestamp,
      state: .completed
    )
  }

  func testHiddenStyleReturnsNilRegardlessOfTimestampFields() {
    let item = makeItem(
      timestamp: Date(timeIntervalSince1970: 1_700_000_000),
      formattedTimestamp: "Custom stamp"
    )

    XCTAssertNil(FKTimelineTimestampFormatter.string(for: item, style: .hidden))
  }

  func testCustomStyleReturnsFormattedTimestampOnly() {
    let item = makeItem(
      timestamp: Date(timeIntervalSince1970: 1_700_000_000),
      formattedTimestamp: "Jun 21, 10:30 AM"
    )

    XCTAssertEqual(
      FKTimelineTimestampFormatter.string(for: item, style: .custom),
      "Jun 21, 10:30 AM"
    )
  }

  func testCustomStyleReturnsNilWhenFormattedTimestampMissing() {
    let item = makeItem(timestamp: Date(timeIntervalSince1970: 1_700_000_000))

    XCTAssertNil(FKTimelineTimestampFormatter.string(for: item, style: .custom))
  }

  func testAbsoluteStylePrefersFormattedTimestampOverRawDate() {
    let item = makeItem(
      timestamp: Date(timeIntervalSince1970: 1_700_000_000),
      formattedTimestamp: "Host-controlled absolute time"
    )

    XCTAssertEqual(
      FKTimelineTimestampFormatter.string(for: item, style: .absolute),
      "Host-controlled absolute time"
    )
  }

  func testAbsoluteStyleFormatsTimestampWhenFormattedValueMissing() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let item = makeItem(timestamp: date)

    let formatted = FKTimelineTimestampFormatter.string(for: item, style: .absolute)

    let expectedFormatter = DateFormatter()
    expectedFormatter.dateStyle = .medium
    expectedFormatter.timeStyle = .short
    let expected = expectedFormatter.string(from: date)

    XCTAssertEqual(formatted, expected)
  }

  func testAbsoluteStyleReturnsNilWhenNoTimestampFieldsPresent() {
    let item = makeItem()

    XCTAssertNil(FKTimelineTimestampFormatter.string(for: item, style: .absolute))
  }

  func testRelativeStyleFormatsTimestampWhenPresent() {
    let oneHourAgo = Date().addingTimeInterval(-3_600)
    let item = makeItem(timestamp: oneHourAgo)

    let formatted = FKTimelineTimestampFormatter.string(for: item, style: .relative)

    XCTAssertNotNil(formatted)
    XCTAssertFalse(formatted?.isEmpty ?? true)
  }

  func testRelativeStyleFallsBackToFormattedTimestampWhenDateMissing() {
    let item = makeItem(formattedTimestamp: "Yesterday at 3:00 PM")

    XCTAssertEqual(
      FKTimelineTimestampFormatter.string(for: item, style: .relative),
      "Yesterday at 3:00 PM"
    )
  }

  func testRelativeStyleReturnsNilWhenNeitherTimestampFieldPresent() {
    let item = makeItem()

    XCTAssertNil(FKTimelineTimestampFormatter.string(for: item, style: .relative))
  }
}
