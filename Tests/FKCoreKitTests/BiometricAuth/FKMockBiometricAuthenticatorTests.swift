import FKCoreKit
import XCTest

final class FKMockBiometricAuthenticatorTests: XCTestCase {
  func testAuthenticateSucceedsWithDefaultMock() async throws {
    let authenticator = FKMockBiometricAuthenticator()
    try await authenticator.authenticate(reason: "Unlock settings")
  }

  func testAuthenticateThrowsConfiguredFailure() async {
    let authenticator = FKMockBiometricAuthenticator(
      authenticateOutcome: .failure(.authenticationFailed)
    )

    do {
      try await authenticator.authenticate(reason: "Unlock settings")
      XCTFail("Expected authenticationFailed")
    } catch let error as FKBiometricError {
      XCTAssertEqual(error, .authenticationFailed)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testAuthenticateThrowsInvalidReasonForWhitespaceOnlyInput() async {
    let authenticator = FKMockBiometricAuthenticator()

    do {
      try await authenticator.authenticate(reason: "   ")
      XCTFail("Expected invalidReason")
    } catch let error as FKBiometricError {
      XCTAssertEqual(error, .invalidReason)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testCapabilityForPolicyUpdatesEvaluatedPolicy() {
    let authenticator = FKMockBiometricAuthenticator()
    let capability = authenticator.capability(for: .biometricsOnly)
    XCTAssertEqual(capability.evaluatedPolicy, .biometricsOnly)
    XCTAssertTrue(capability.canAuthenticate)
  }

  func testAuthenticateWithExplicitPolicyAndOptionsHonorsOutcome() async throws {
    let authenticator = FKMockBiometricAuthenticator(
      authenticateOutcome: .failure(.userCancelled)
    )

    do {
      try await authenticator.authenticate(
        reason: "Confirm purchase",
        policy: .biometricsOnly,
        options: FKBiometricAuthOptions(localizedFallbackTitle: "Use passcode")
      )
      XCTFail("Expected userCancelled")
    } catch let error as FKBiometricError {
      XCTAssertEqual(error, .userCancelled)
    }
  }

  func testCapabilityReflectsConfiguredBiometryType() {
    let authenticator = FKMockBiometricAuthenticator(
      capabilityResult: FKBiometricCapability(
        canAuthenticate: false,
        biometryType: .touchID,
        isBiometryEnrolled: false,
        isPasscodeSet: true,
        evaluatedPolicy: .biometricsOrPasscode
      )
    )

    let capability = authenticator.capability(for: .devicePasscode)

    XCTAssertFalse(capability.canAuthenticate)
    XCTAssertEqual(capability.biometryType, .touchID)
    XCTAssertEqual(capability.evaluatedPolicy, .devicePasscode)
  }

  func testAuthenticateThrowsBiometryNotAvailableWhenConfigured() async {
    let authenticator = FKMockBiometricAuthenticator(
      authenticateOutcome: .failure(.biometryNotAvailable)
    )

    do {
      try await authenticator.authenticate(reason: "Unlock")
      XCTFail("Expected biometryNotAvailable")
    } catch let error as FKBiometricError {
      XCTAssertEqual(error, .biometryNotAvailable)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
