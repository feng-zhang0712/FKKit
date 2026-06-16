import FKCoreKit
import XCTest

final class DispatchQueueExtensionTests: XCTestCase {
  func testAsyncAfterClampsNegativeDelayToImmediateExecution() {
    let expectation = expectation(description: "delayed work runs")
    DispatchQueue.global(qos: .userInitiated).fk_asyncAfter(delay: -5) {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1)
  }

  func testAsyncOnMainDispatchesWorkToMainQueue() {
    let expectation = expectation(description: "main queue work runs")
    DispatchQueue.fk_asyncOnMain { expectation.fulfill() }
    wait(for: [expectation], timeout: 1)
  }
}
