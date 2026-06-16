import FKCoreKit
import UIKit

/// Stubs for FKBusinessVersionManager integration tests.
enum BusinessKitTestFixtures {
  final class InfoProvider: FKBusinessInfoProviding {
    var bundleID = "com.fkkit.tests"
    var appVersion = "1.0.0"
    var buildNumber = "100"
    var systemVersion = "18.0"
    var deviceModelIdentifier = "iPhone"
    var screenSize = CGSize(width: 390, height: 844)
    var channel = "test"
    var environment: FKBusinessEnvironment = .debug
  }

  final class AlertManager: FKBusinessAlertManaging {
    private(set) var presentCount = 0

    func presentOnce(
      id: String,
      title: String?,
      message: String?,
      actions: [FKAlertAction],
      presenter: UIViewController?
    ) {
      presentCount += 1
    }
  }

  final class RemoteVersionProvider: FKRemoteVersionProviding, @unchecked Sendable {
    let remote: FKRemoteVersionInfo

    init(remote: FKRemoteVersionInfo) {
      self.remote = remote
    }

    func fetchRemoteVersion() async throws -> FKRemoteVersionInfo {
      remote
    }
  }
}
