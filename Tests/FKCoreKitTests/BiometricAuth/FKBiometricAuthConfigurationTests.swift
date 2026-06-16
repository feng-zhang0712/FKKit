import FKCoreKit
import XCTest

final class FKBiometricAuthConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesBiometricsOrPasscodePolicy() {
    let configuration = FKBiometricAuthConfiguration()

    XCTAssertEqual(configuration.defaultPolicy, .biometricsOrPasscode)
    XCTAssertNil(configuration.reuseDuration)
    XCTAssertTrue(configuration.invalidateContextAfterSuccess)
    XCTAssertTrue(configuration.invalidateContextAfterFailure)
  }

  func testConfigurationStoresCustomPolicyAndReuseDuration() {
    let configuration = FKBiometricAuthConfiguration(
      defaultPolicy: .biometricsOnly,
      reuseDuration: 30,
      localizedFallbackTitle: "Use Passcode",
      invalidateContextAfterSuccess: false,
      invalidateContextAfterFailure: false
    )

    XCTAssertEqual(configuration.defaultPolicy, .biometricsOnly)
    XCTAssertEqual(configuration.reuseDuration, 30)
    XCTAssertEqual(configuration.localizedFallbackTitle, "Use Passcode")
    XCTAssertFalse(configuration.invalidateContextAfterSuccess)
    XCTAssertFalse(configuration.invalidateContextAfterFailure)
  }
}
