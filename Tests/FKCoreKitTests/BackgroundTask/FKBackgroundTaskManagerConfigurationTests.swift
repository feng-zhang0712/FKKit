import FKCoreKit
import XCTest

final class FKBackgroundTaskManagerConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesProductionSafeFlags() {
    let configuration = FKBackgroundTaskManagerConfiguration.default

    XCTAssertFalse(configuration.allowsMultipleInstall)
    XCTAssertFalse(configuration.logScheduling)
    XCTAssertFalse(configuration.debugLogPendingTasks)
  }

  func testConfigurationStoresCustomDebugAndInstallFlags() {
    let configuration = FKBackgroundTaskManagerConfiguration(
      allowsMultipleInstall: true,
      logScheduling: true,
      debugLogPendingTasks: true
    )

    XCTAssertTrue(configuration.allowsMultipleInstall)
    XCTAssertTrue(configuration.logScheduling)
    XCTAssertTrue(configuration.debugLogPendingTasks)
  }
}
