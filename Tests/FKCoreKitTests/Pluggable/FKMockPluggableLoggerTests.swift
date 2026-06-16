import FKCoreKit
import XCTest

final class FKMockPluggableLoggerTests: XCTestCase {
  func testLogCapturesEntryAtOrAboveMinimumLevel() {
    let logger = FKMockPluggableLogger()
    logger.minimumLevel = .warning

    logger.log(level: .debug, "debug-line", file: "File.swift", function: "test()", line: 1)
    logger.log(level: .warning, "warn-line", file: "File.swift", function: "test()", line: 2)

    let entries = logger.capturedEntries()
    XCTAssertEqual(entries.count, 1)
    XCTAssertEqual(entries[0].level, .warning)
    XCTAssertEqual(entries[0].message, "warn-line")
  }

  func testResetClearsCapturedEntries() {
    let logger = FKMockPluggableLogger()
    logger.log(level: .info, "line", file: "A.swift", function: "fn", line: 10)
    logger.reset()
    XCTAssertTrue(logger.capturedEntries().isEmpty)
  }
}
