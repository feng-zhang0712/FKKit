import FKUIKit
import XCTest

final class FKWebViewDefaultsTests: XCTestCase {
  func testInAppBrowserUsesCompactToolbarAndExternalTargetBlank() {
    let configuration = FKWebViewDefaults.inAppBrowser()

    guard case let .compactToolbar(showsCloseButton) = configuration.presentation.chrome else {
      XCTFail("Expected compact toolbar chrome")
      return
    }
    XCTAssertTrue(showsCloseButton)
    XCTAssertEqual(configuration.navigation.policy.targetBlank, .openExternally)
  }

  func testEphemeralAuthUsesNonPersistentStoreAndOfflineEmptyState() {
    let configuration = FKWebViewDefaults.ephemeralAuth(customSchemes: ["myapp": .notifyHost])

    XCTAssertTrue(configuration.security.usesEphemeralWebsiteDataStore)
    XCTAssertTrue(configuration.reachability.showsOfflineEmptyStateBeforeLoad)
    XCTAssertEqual(configuration.navigation.policy.customSchemes["myapp"], .notifyHost)
  }

  func testDefaultConfigurationUsesLinearProgressPresentation() {
    let configuration = FKWebViewDefaults.defaultConfiguration
    XCTAssertEqual(configuration.presentation.progress.presentation, .linearBar)
    XCTAssertTrue(configuration.presentation.progress.hidesWhenComplete)
  }
}
