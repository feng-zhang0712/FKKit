import FKCoreKit
import XCTest

final class FKBackgroundProcessingRequestTests: XCTestCase {
  func testRequestStoresSchedulingConstraints() {
    let beginDate = Date(timeIntervalSince1970: 1_700_000_000)
    let request = FKBackgroundProcessingRequest(
      identifier: "com.fkkit.refresh",
      earliestBeginDate: beginDate,
      requiresNetworkConnectivity: true,
      requiresExternalPower: true
    )

    XCTAssertEqual(request.identifier, "com.fkkit.refresh")
    XCTAssertEqual(request.earliestBeginDate, beginDate)
    XCTAssertTrue(request.requiresNetworkConnectivity)
    XCTAssertTrue(request.requiresExternalPower)
  }

  func testPendingSummaryReflectsProcessingRequirements() {
    let beginDate = Date(timeIntervalSince1970: 1_700_000_100)
    let summary = FKBackgroundTaskPendingSummary(
      identifier: "com.fkkit.sync",
      kind: .processing,
      earliestBeginDate: beginDate,
      requiresNetworkConnectivity: true,
      requiresExternalPower: false
    )

    XCTAssertEqual(summary.identifier, "com.fkkit.sync")
    XCTAssertEqual(summary.kind, .processing)
    XCTAssertEqual(summary.earliestBeginDate, beginDate)
    XCTAssertTrue(summary.requiresNetworkConnectivity)
    XCTAssertFalse(summary.requiresExternalPower)
  }
}
