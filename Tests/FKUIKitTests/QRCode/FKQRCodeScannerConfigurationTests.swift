import FKUIKit
import XCTest

final class FKQRCodeScannerConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesOnceScanModeAndCooldown() {
    let configuration = FKQRCodeScannerConfiguration.default

    XCTAssertEqual(configuration.scanMode, .once)
    XCTAssertEqual(configuration.cooldownInterval, 2, accuracy: 0.001)
    XCTAssertFalse(configuration.allowsMultipleCallbacks)
    XCTAssertTrue(configuration.showsTorchButton)
    XCTAssertTrue(configuration.hapticsOnSuccess)
  }

  func testConfigurationStoresNavigationAndSimulatorMockPayload() {
    let configuration = FKQRCodeScannerConfiguration(
      scanMode: .continuous,
      cooldownInterval: 0.5,
      allowsMultipleCallbacks: true,
      navigationPolicy: .openHTTPInApp,
      simulatorMockRawValue: "custom-payload"
    )

    XCTAssertEqual(configuration.scanMode, .continuous)
    XCTAssertEqual(configuration.cooldownInterval, 0.5, accuracy: 0.001)
    XCTAssertTrue(configuration.allowsMultipleCallbacks)
    XCTAssertEqual(configuration.navigationPolicy, .openHTTPInApp)
    XCTAssertEqual(configuration.simulatorMockRawValue, "custom-payload")
  }
}
