import FKCoreKit
import XCTest

#if os(iOS)
@MainActor
final class FKPermissionsTests: XCTestCase {
  func testBatchRequestEmptyArrayReturnsEmptyDictionary() async {
    let results = await FKPermissions.shared.request([FKPermissionRequest]())

    XCTAssertTrue(results.isEmpty)
  }

  func testInvalidateObservationTokenSuppressesCallbacksDuringRequest() async {
    let callbackCount = LockedCounter()
    let token = FKPermissions.shared.observeStatusChanges { _, _ in
      callbackCount.increment()
    }
    token.invalidate()

    _ = await FKPermissions.shared.request(FKPermissionRequest(kind: .camera))

    XCTAssertEqual(callbackCount.current, 0)
  }

  func testBatchRequestReturnsResultForEachKind() async {
    let requests: [FKPermissionRequest] = [
      FKPermissionRequest(kind: .camera),
      FKPermissionRequest(kind: .microphone),
    ]
    let results = await FKPermissions.shared.request(requests)

    XCTAssertEqual(results.count, 2)
    XCTAssertNotNil(results[.camera])
    XCTAssertNotNil(results[.microphone])
  }
}
#endif
