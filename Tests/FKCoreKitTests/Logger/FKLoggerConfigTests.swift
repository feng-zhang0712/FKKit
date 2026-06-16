import FKCoreKit
import XCTest

final class FKLoggerConfigTests: XCTestCase {
  func testDebugDefaultEnablesAllLevelsAndFilePersistence() {
    let configuration = FKLoggerConfig.debugDefault

    XCTAssertTrue(configuration.isEnabled)
    XCTAssertEqual(configuration.enabledLevels, Set(FKLogLevel.allCases))
    XCTAssertTrue(configuration.persistsToFile)
    XCTAssertTrue(configuration.usesColorizedConsole)
  }

  func testReleaseDefaultDisablesLoggingExceptErrors() {
    let configuration = FKLoggerConfig.releaseDefault

    XCTAssertFalse(configuration.isEnabled)
    XCTAssertEqual(configuration.enabledLevels, [.error])
    XCTAssertFalse(configuration.persistsToFile)
    XCTAssertFalse(configuration.usesColorizedConsole)
  }
}
