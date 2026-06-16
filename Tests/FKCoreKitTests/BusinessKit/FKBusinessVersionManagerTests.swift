import FKCoreKit
import XCTest

final class FKBusinessVersionManagerTests: XCTestCase {
  private var infoProvider: BusinessKitTestFixtures.InfoProvider!
  private var alertManager: BusinessKitTestFixtures.AlertManager!
  private var manager: FKBusinessVersionManager!

  override func setUp() {
    super.setUp()
    infoProvider = BusinessKitTestFixtures.InfoProvider()
    alertManager = BusinessKitTestFixtures.AlertManager()
    manager = FKBusinessVersionManager(infoProvider: infoProvider, alertManager: alertManager)
  }

  override func tearDown() {
    manager = nil
    alertManager = nil
    infoProvider = nil
    super.tearDown()
  }

  func testAppMetadataReflectsInfoProvider() {
    let metadata = manager.appMetadata()
    XCTAssertEqual(metadata.bundleID, infoProvider.bundleID)
    XCTAssertEqual(metadata.version, infoProvider.appVersion)
    XCTAssertEqual(metadata.build, infoProvider.buildNumber)
  }

  func testCheckForUpdateReturnsUpToDateWhenRemoteNotNewer() async throws {
    infoProvider.appVersion = "2.0.0"
    let provider = BusinessKitTestFixtures.RemoteVersionProvider(
      remote: FKRemoteVersionInfo(version: "1.5.0")
    )

    let result = try await manager.checkForUpdate(using: provider)
    XCTAssertEqual(result.decision, .upToDate)
  }

  func testCheckForUpdateReturnsOptionalUpdateWhenRemoteIsNewer() async throws {
    infoProvider.appVersion = "1.0.0"
    let provider = BusinessKitTestFixtures.RemoteVersionProvider(
      remote: FKRemoteVersionInfo(version: "1.1.0")
    )

    let result = try await manager.checkForUpdate(using: provider)
    XCTAssertEqual(result.decision, .optionalUpdate)
  }

  func testCheckForUpdateReturnsForceUpdateWhenRemoteRequiresIt() async throws {
    infoProvider.appVersion = "9.0.0"
    let provider = BusinessKitTestFixtures.RemoteVersionProvider(
      remote: FKRemoteVersionInfo(version: "1.0.0", isForceUpdate: true)
    )

    let result = try await manager.checkForUpdate(using: provider)
    XCTAssertEqual(result.decision, .forceUpdate)
  }
}
