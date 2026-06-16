import FKCoreKit
import XCTest

final class FKFileManagerConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesProductionSafeDiskAndZipDefaults() {
    let configuration = FKFileManagerConfiguration()

    XCTAssertEqual(configuration.minimumRequiredDiskSpace, 50 * 1024 * 1024)
    XCTAssertEqual(configuration.workingDirectoryName, "FKFileManager")
    XCTAssertTrue(configuration.isZipEnabled)
    XCTAssertEqual(configuration.zipDiskSpaceSafetyFactor, 1.1, accuracy: 0.001)
  }

  func testConfigurationStoresCustomSessionAndPersistenceKeys() {
    let configuration = FKFileManagerConfiguration(
      backgroundSessionIdentifier: "com.example.downloads",
      minimumRequiredDiskSpace: 128,
      persistenceKey: "transfers.v2",
      workingDirectoryName: "Downloads",
      isZipEnabled: false,
      zipDiskSpaceSafetyFactor: 1.5
    )

    XCTAssertEqual(configuration.backgroundSessionIdentifier, "com.example.downloads")
    XCTAssertEqual(configuration.minimumRequiredDiskSpace, 128)
    XCTAssertEqual(configuration.persistenceKey, "transfers.v2")
    XCTAssertEqual(configuration.workingDirectoryName, "Downloads")
    XCTAssertFalse(configuration.isZipEnabled)
    XCTAssertEqual(configuration.zipDiskSpaceSafetyFactor, 1.5, accuracy: 0.001)
  }
}
