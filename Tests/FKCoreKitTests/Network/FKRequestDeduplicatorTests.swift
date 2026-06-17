import FKCoreKit
import XCTest

final class FKRequestDeduplicatorTests: XCTestCase {
  func testShouldProceedAllowsFirstRequestForKey() {
    let deduplicator = FKRequestDeduplicator()

    XCTAssertTrue(deduplicator.shouldProceed(key: "GET-/user"))
  }

  func testShouldProceedRejectsDuplicateInFlightKey() {
    let deduplicator = FKRequestDeduplicator()
    let key = "GET-/user"

    XCTAssertTrue(deduplicator.shouldProceed(key: key))
    XCTAssertFalse(deduplicator.shouldProceed(key: key))
  }

  func testCompleteReleasesKeyForSubsequentRequests() {
    let deduplicator = FKRequestDeduplicator()
    let key = "GET-/user"

    XCTAssertTrue(deduplicator.shouldProceed(key: key))
    deduplicator.complete(key: key)
    XCTAssertTrue(deduplicator.shouldProceed(key: key))
  }

  func testDifferentKeysAreTrackedIndependently() {
    let deduplicator = FKRequestDeduplicator()

    XCTAssertTrue(deduplicator.shouldProceed(key: "a"))
    XCTAssertTrue(deduplicator.shouldProceed(key: "b"))
    XCTAssertFalse(deduplicator.shouldProceed(key: "a"))
  }
}
