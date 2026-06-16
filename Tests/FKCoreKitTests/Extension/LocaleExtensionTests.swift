import FKCoreKit
import Foundation
import XCTest

final class LocaleExtensionTests: XCTestCase {
  func testPOSIXLocaleUsesStableIdentifier() {
    XCTAssertEqual(Locale.fk_posix.identifier, "en_US_POSIX")
  }

  func testPOSIXLocaleIsDistinctFromCurrent() {
    XCTAssertNotEqual(Locale.fk_posix.identifier, Locale.current.identifier)
  }
}
