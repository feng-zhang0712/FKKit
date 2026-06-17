@testable import FKCoreKit
import XCTest

final class FKNetworkRetryExecutorTests: XCTestCase {
  func testIsHTTPMethodRetryableAllowsGETWhenIdempotentMethodsOnly() {
    let policy = FKNetworkRetryPolicy(maxRetryCount: 3, idempotentMethodsOnly: true)

    XCTAssertTrue(
      FKNetworkRetryExecutor.isHTTPMethodRetryable(method: .get, isIdempotent: false, policy: policy)
    )
    XCTAssertFalse(
      FKNetworkRetryExecutor.isHTTPMethodRetryable(method: .post, isIdempotent: false, policy: policy)
    )
  }

  func testIsHTTPMethodRetryableAllowsMarkedIdempotentPOST() {
    let policy = FKNetworkRetryPolicy(maxRetryCount: 3, idempotentMethodsOnly: true)

    XCTAssertTrue(
      FKNetworkRetryExecutor.isHTTPMethodRetryable(method: .post, isIdempotent: true, policy: policy)
    )
  }

  func testShouldRetryReturnsFalseWhenBudgetExhausted() {
    let policy = FKNetworkRetryPolicy(
      maxRetryCount: 2,
      retryableHTTPStatusCodes: [503],
      idempotentMethodsOnly: true
    )
    let error = NetworkError.serverError(statusCode: 503, message: nil)

    XCTAssertTrue(FKNetworkRetryExecutor.shouldRetry(error: error, httpRetryCount: 0, policy: policy))
    XCTAssertTrue(FKNetworkRetryExecutor.shouldRetry(error: error, httpRetryCount: 1, policy: policy))
    XCTAssertFalse(FKNetworkRetryExecutor.shouldRetry(error: error, httpRetryCount: 2, policy: policy))
  }

  func testShouldRetryReturnsFalseForOfflineAndCancelled() {
    let policy = FKNetworkRetryPolicy(
      maxRetryCount: 3,
      retryableHTTPStatusCodes: [503],
      idempotentMethodsOnly: true
    )

    XCTAssertFalse(FKNetworkRetryExecutor.shouldRetry(error: .offline, httpRetryCount: 0, policy: policy))
    XCTAssertFalse(
      FKNetworkRetryExecutor.shouldRetry(error: .requestCancelled, httpRetryCount: 0, policy: policy)
    )
  }

  func testDelayUsesConstantBackoff() {
    let policy = FKNetworkRetryPolicy(maxRetryCount: 3, backoff: .constant(0.25), idempotentMethodsOnly: true)

    XCTAssertEqual(FKNetworkRetryExecutor.delay(forAttempt: 1, policy: policy), 0.25, accuracy: 0.001)
    XCTAssertEqual(FKNetworkRetryExecutor.delay(forAttempt: 3, policy: policy), 0.25, accuracy: 0.001)
  }
}
