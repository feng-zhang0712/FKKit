import FKCoreKit
import XCTest

final class FKBusinessKitConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesAppStoreChannelAndSystemAlertBackend() {
    let configuration = FKBusinessKitConfiguration()

    XCTAssertEqual(configuration.channel, "AppStore")
    XCTAssertEqual(configuration.defaultLanguageCode, "en")
    XCTAssertEqual(configuration.analyticsMaxBatchSize, 20)
    XCTAssertEqual(configuration.alertBackend, .systemAlert)
  }

  func testConfigurationStoresCustomAnalyticsAndEnvironmentValues() {
    let configuration = FKBusinessKitConfiguration(
      channel: "Enterprise",
      environment: .release,
      analyticsFlushInterval: 30,
      analyticsMaxBatchSize: 50,
      analyticsMaxRetryCount: 5,
      alertBackend: .fkAlert
    )

    XCTAssertEqual(configuration.channel, "Enterprise")
    XCTAssertEqual(configuration.environment, .release)
    XCTAssertEqual(configuration.analyticsFlushInterval, 30, accuracy: 0.001)
    XCTAssertEqual(configuration.analyticsMaxBatchSize, 50)
    XCTAssertEqual(configuration.analyticsMaxRetryCount, 5)
    XCTAssertEqual(configuration.alertBackend, .fkAlert)
  }
}
