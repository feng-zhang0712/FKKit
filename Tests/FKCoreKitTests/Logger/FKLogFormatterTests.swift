import FKCoreKit
import XCTest

final class FKLogFormatterTests: XCTestCase {
  private let formatter = FKLogFormatter()
  private let timestamp = Date(timeIntervalSince1970: 1_700_000_000)

  private func makeEvent(
    level: FKLogLevel = .info,
    message: String = "hello",
    metadata: [String: String] = [:]
  ) -> FKLogEvent {
    FKLogEvent(
      level: level,
      message: message,
      file: "/tmp/FKKit/SampleFile.swift",
      function: "testFunction()",
      line: 42,
      timestamp: timestamp,
      metadata: metadata
    )
  }

  func testFormatIncludesMessageLevelAndMetadata() {
    var config = LoggerTestFixtures.testLoggerConfig()
    config.prefix = "[FK]"
    config.includesTimestamp = true
    config.includesFileName = true
    config.includesFunctionName = true
    config.includesLineNumber = true
    config.usesEmoji = true

    let line = formatter.format(
      event: makeEvent(metadata: ["userID": "42", "route": "home"]),
      config: config
    )

    XCTAssertTrue(line.contains("[FK]"))
    XCTAssertTrue(line.contains("[INFO]"))
    XCTAssertTrue(line.contains("hello"))
    XCTAssertTrue(line.contains("SampleFile.swift"))
    XCTAssertTrue(line.contains("testFunction()"))
    XCTAssertTrue(line.contains("#42"))
    XCTAssertTrue(line.contains("route=home"))
    XCTAssertTrue(line.contains("userID=42"))
  }

  func testFormatOmitsOptionalSectionsWhenDisabled() {
    let config = LoggerTestFixtures.testLoggerConfig()

    let line = formatter.format(event: makeEvent(), config: config)

    XCTAssertEqual(line, "[TestLogger] [INFO] hello")
  }
}
