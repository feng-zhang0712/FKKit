import FKCoreKit
import Foundation
import XCTest

final class TimeZoneExtensionTests: XCTestCase {
  func testUTCTimeZoneHasZeroGMTOffset() {
    XCTAssertEqual(TimeZone.fk_utc.secondsFromGMT(), 0)
  }

  func testUTCTimeZoneIdentifierContainsUTC() {
    XCTAssertTrue(TimeZone.fk_utc.identifier.contains("GMT"))
  }
}
