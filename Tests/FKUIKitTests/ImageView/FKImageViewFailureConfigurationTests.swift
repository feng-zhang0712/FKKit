import FKUIKit
import XCTest

final class FKImageViewFailureConfigurationTests: XCTestCase {
  func testResolvedMessagePrefersExplicitMessage() {
    let configuration = FKImageViewFailureConfiguration(message: "Custom failure")
    XCTAssertEqual(configuration.resolvedMessage(for: .network), "Custom failure")
  }

  func testResolvedMessageReturnsNilForCancelledReason() {
    let configuration = FKImageViewFailureConfiguration()
    XCTAssertNil(configuration.resolvedMessage(for: .cancelled))
  }

  func testResolvedMessageUsesCustomPayloadForCustomReason() {
    let configuration = FKImageViewFailureConfiguration()
    XCTAssertEqual(configuration.resolvedMessage(for: .custom(message: "decode failed")), "decode failed")
  }

  func testResolvedRetryTitleFallsBackToLocalizedDefault() {
    let configuration = FKImageViewFailureConfiguration()
    XCTAssertFalse(configuration.resolvedRetryTitle.isEmpty)
  }
}
