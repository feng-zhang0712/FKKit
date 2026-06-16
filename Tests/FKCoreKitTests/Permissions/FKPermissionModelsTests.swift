import FKCoreKit
import XCTest

final class FKPermissionModelsTests: XCTestCase {
  func testIsGrantedReturnsTrueForAccessibleStatuses() {
    let grantedStatuses: [FKPermissionStatus] = [
      .authorized,
      .limited,
      .provisional,
      .ephemeral,
    ]

    for status in grantedStatuses {
      let result = FKPermissionResult(kind: .camera, status: status)
      XCTAssertTrue(result.isGranted, "Expected granted for \(status)")
    }
  }

  func testIsGrantedReturnsFalseForBlockedStatuses() {
    let blockedStatuses: [FKPermissionStatus] = [
      .notDetermined,
      .denied,
      .restricted,
      .deviceDisabled,
    ]

    for status in blockedStatuses {
      let result = FKPermissionResult(kind: .camera, status: status)
      XCTAssertFalse(result.isGranted, "Expected not granted for \(status)")
    }
  }

  func testPermissionRequestPreservesPrePromptAndPurposeKey() {
    let prePrompt = FKPermissionPrePrompt(
      title: "Location",
      message: "We use location for delivery tracking.",
      confirmTitle: "Continue",
      cancelTitle: "Not now"
    )
    let request = FKPermissionRequest(
      kind: .locationTemporaryFullAccuracy,
      prePrompt: prePrompt,
      temporaryLocationPurposeKey: "DeliveryTracking"
    )

    XCTAssertEqual(request.kind, .locationTemporaryFullAccuracy)
    XCTAssertEqual(request.prePrompt, prePrompt)
    XCTAssertEqual(request.temporaryLocationPurposeKey, "DeliveryTracking")
  }

  func testPermissionErrorEquatableCases() {
    XCTAssertEqual(FKPermissionError.prePromptCancelled, .prePromptCancelled)
    XCTAssertEqual(FKPermissionError.unavailable, .unavailable)
    XCTAssertEqual(FKPermissionError.custom("detail"), .custom("detail"))
    XCTAssertNotEqual(FKPermissionError.custom("a"), .custom("b"))
  }
}
