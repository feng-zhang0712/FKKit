import FKCoreKit
import Foundation
import XCTest

final class BundleExtensionTests: XCTestCase {
  func testVersionHelpersReturnNonEmptyStringsForMainBundle() {
    let bundle = Bundle.main

    XCTAssertFalse(bundle.fk_shortVersionString.isEmpty)
    XCTAssertFalse(bundle.fk_buildVersionString.isEmpty)
    XCTAssertTrue(bundle.fk_versionLabel.contains("("))
  }

  func testDisplayNameReturnsNonEmptyLabelForMainBundle() {
    XCTAssertFalse(Bundle.main.fk_displayName.isEmpty)
  }
}
