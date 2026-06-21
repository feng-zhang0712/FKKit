@testable import FKUIKit
import AVFoundation
import XCTest

final class FKMediaErrorMapperTests: XCTestCase {
  func testMapReturnsSameValueForExistingMediaError() {
    let original = FKMediaError.cancelled

    XCTAssertEqual(FKMediaErrorMapper.map(original, engine: .avFoundation), .cancelled)
  }

  func testMapNetworkUnavailableForOfflineURLError() {
    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)

    XCTAssertEqual(FKMediaErrorMapper.map(error, engine: .avFoundation), .networkUnavailable)
  }

  func testMapCancelledForURLCancelledError() {
    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)

    XCTAssertEqual(FKMediaErrorMapper.map(error, engine: .avFoundation), .cancelled)
  }

  func testMapHTTPStatusFromUserInfo() {
    let error = NSError(
      domain: "Test",
      code: 1,
      userInfo: ["HTTPStatusCode": 503]
    )

    XCTAssertEqual(FKMediaErrorMapper.map(error, engine: .avFoundation), .httpStatus(code: 503))
  }

  func testMapDRMFailedForUnavailableAVFoundationContent() {
    let error = NSError(
      domain: AVFoundationErrorDomain,
      code: AVError.contentIsUnavailable.rawValue
    )

    let mapped = FKMediaErrorMapper.map(error, engine: .avFoundation)
    if case let .drmFailed(message) = mapped {
      XCTAssertFalse(message.isEmpty)
    } else {
      XCTFail("Expected drmFailed, got \(mapped)")
    }
  }

  func testMapEngineFailedForUnknownErrors() {
    let error = NSError(domain: "Custom", code: 99, userInfo: [NSLocalizedDescriptionKey: "boom"])

    XCTAssertEqual(
      FKMediaErrorMapper.map(error, engine: .avFoundation),
      .engineFailed(engine: .avFoundation, message: "boom")
    )
  }

  func testMapPlayerItemErrorReturnsNilForNilInput() {
    XCTAssertNil(FKMediaErrorMapper.mapPlayerItemError(nil))
  }

  func testMapPlayerItemErrorWrapsUnderlyingError() {
    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)

    XCTAssertEqual(
      FKMediaErrorMapper.mapPlayerItemError(error),
      .networkUnavailable
    )
  }
}
