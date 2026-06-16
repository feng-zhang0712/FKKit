import FKCoreKit
import Foundation

/// Captures formatted log lines for assertions in `FKLogger` tests.
final class CapturingConsoleOutputter: FKConsoleOutputting, @unchecked Sendable {
  private let lock = NSLock()
  private var lines: [(line: String, level: FKLogLevel)] = []

  func output(line: String, level: FKLogLevel, config: FKLoggerConfig) {
    lock.lock()
    lines.append((line, level))
    lock.unlock()
  }

  func capturedLines() -> [(line: String, level: FKLogLevel)] {
    lock.lock()
    defer { lock.unlock() }
    return lines
  }

  func reset() {
    lock.lock()
    lines = []
    lock.unlock()
  }
}

/// Discards file persistence during logger tests.
struct NoOpLogFileManager: FKLogFileManaging {
  func write(line: String, timestamp: Date, config: FKLoggerConfig) {}

  func allLogFiles() -> [URL] { [] }

  func clearAllLogs() {}

  func exportLogsArchive() -> URL? { nil }
}

enum LoggerTestFixtures {
  static func testLoggerConfig(
    enabledLevels: Set<FKLogLevel> = Set(FKLogLevel.allCases),
    persistsToFile: Bool = false
  ) -> FKLoggerConfig {
    FKLoggerConfig(
      isEnabled: true,
      enabledLevels: enabledLevels,
      prefix: "[TestLogger]",
      includesTimestamp: false,
      includesFileName: false,
      includesFunctionName: false,
      includesLineNumber: false,
      usesColorizedConsole: false,
      usesEmoji: false,
      persistsToFile: persistsToFile,
      maxFileSizeInBytes: 1_048_576,
      maxStorageSizeInBytes: 1_048_576,
      rotatesDaily: false
    )
  }
}
