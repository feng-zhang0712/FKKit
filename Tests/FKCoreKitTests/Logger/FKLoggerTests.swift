import FKCoreKit
import XCTest

final class FKLoggerTests: XCTestCase {
  func testLogRoutesFormattedLineToConsoleOutputter() {
    let outputter = CapturingConsoleOutputter()
    let logger = FKLogger(
      config: LoggerTestFixtures.testLoggerConfig(enabledLevels: [.info]),
      formatter: FKLogFormatter(),
      fileManager: NoOpLogFileManager(),
      consoleOutputter: outputter
    )

    logger.info("network-ready")
    logger.flushSynchronously()

    let lines = outputter.capturedLines()
    XCTAssertEqual(lines.count, 1)
    XCTAssertEqual(lines[0].level, .info)
    XCTAssertTrue(lines[0].line.contains("network-ready"))
  }

  func testLogSkipsDisabledLevels() {
    let outputter = CapturingConsoleOutputter()
    let logger = FKLogger(
      config: LoggerTestFixtures.testLoggerConfig(enabledLevels: [.error]),
      formatter: FKLogFormatter(),
      fileManager: NoOpLogFileManager(),
      consoleOutputter: outputter
    )

    logger.debug("ignored")
    logger.error("recorded")
    logger.flushSynchronously()

    let lines = outputter.capturedLines()
    XCTAssertEqual(lines.count, 1)
    XCTAssertEqual(lines[0].level, .error)
  }

  func testSetLevelTogglesEmissionAtRuntime() {
    let outputter = CapturingConsoleOutputter()
    let logger = FKLogger(
      config: LoggerTestFixtures.testLoggerConfig(enabledLevels: []),
      formatter: FKLogFormatter(),
      fileManager: NoOpLogFileManager(),
      consoleOutputter: outputter
    )

    logger.setLevel(.warning, isEnabled: true)
    logger.warning("enabled-at-runtime")
    logger.flushSynchronously()

    XCTAssertEqual(outputter.capturedLines().count, 1)
  }
}
