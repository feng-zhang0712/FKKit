import FKCoreKit
import XCTest

final class FKNetworkRetryPolicyTests: XCTestCase {
  func testInitClampsMaxRetryCountIntoZeroThroughFive() {
    XCTAssertEqual(FKNetworkRetryPolicy(maxRetryCount: -3).maxRetryCount, 0)
    XCTAssertEqual(FKNetworkRetryPolicy(maxRetryCount: 99).maxRetryCount, 5)
  }

  func testConservativeGETPresetRetriesTransientFailures() {
    let policy = FKNetworkRetryPolicy.conservativeGET

    XCTAssertEqual(policy.maxRetryCount, 3)
    XCTAssertTrue(policy.idempotentMethodsOnly)
    XCTAssertTrue(policy.retryableHTTPStatusCodes.contains(503))
    XCTAssertTrue(policy.retryableNetworkErrors.contains(.timedOut))
    if case let .exponential(base, multiplier, jitter) = policy.backoff {
      XCTAssertEqual(base, 0.5, accuracy: 0.001)
      XCTAssertEqual(multiplier, 2, accuracy: 0.001)
      XCTAssertEqual(jitter, 0.1, accuracy: 0.001)
    } else {
      XCTFail("Expected exponential backoff")
    }
  }
}
