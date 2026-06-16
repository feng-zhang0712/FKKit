import FKCoreKit
import XCTest

final class FKLocalNotificationPresentationOptionsTests: XCTestCase {
  func testStandardIncludesBannerListAndSound() {
    let options = FKLocalNotificationPresentationOptions.standard

    XCTAssertTrue(options.contains(.banner))
    XCTAssertTrue(options.contains(.list))
    XCTAssertTrue(options.contains(.sound))
    XCTAssertFalse(options.contains(.badge))
  }

  func testOptionSetCombinesIndividualFlags() {
    let options: FKLocalNotificationPresentationOptions = [.banner, .badge]

    XCTAssertTrue(options.contains(.banner))
    XCTAssertTrue(options.contains(.badge))
    XCTAssertFalse(options.contains(.sound))
  }
}
