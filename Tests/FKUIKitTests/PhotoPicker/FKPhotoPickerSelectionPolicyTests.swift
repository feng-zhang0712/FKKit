import FKUIKit
import XCTest

final class FKPhotoPickerSelectionPolicyTests: XCTestCase {
  func testEffectiveLimitClampsToSupportedRange() {
    XCTAssertEqual(FKPhotoPickerSelectionPolicy(limit: 0).effectiveLimit, 1)
    XCTAssertEqual(FKPhotoPickerSelectionPolicy(limit: 100).effectiveLimit, 50)
    XCTAssertEqual(FKPhotoPickerSelectionPolicy(limit: 9).effectiveLimit, 9)
  }

  func testOverflowTrimLimitUsesEffectiveLimitForFailBehavior() {
    let policy = FKPhotoPickerSelectionPolicy(limit: 5, overflowBehavior: .fail)
    XCTAssertEqual(policy.overflowTrimLimit, 5)
  }

  func testOverflowTrimLimitClampsTakeFirstLimit() {
    let policy = FKPhotoPickerSelectionPolicy(limit: 10, overflowBehavior: .takeFirst(limit: 0))
    XCTAssertEqual(policy.overflowTrimLimit, 1)

    let capped = FKPhotoPickerSelectionPolicy(limit: 4, overflowBehavior: .takeFirst(limit: 99))
    XCTAssertEqual(capped.overflowTrimLimit, 4)
  }
}
