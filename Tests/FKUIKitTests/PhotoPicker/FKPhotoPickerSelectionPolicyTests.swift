import FKUIKit
import XCTest

final class FKPhotoPickerSelectionPolicyTests: XCTestCase {
  func testEffectiveLimitClampsToSupportedRange() {
    let policy = FKPhotoPickerSelectionPolicy(limit: 100)

    XCTAssertEqual(policy.effectiveLimit, 50)
  }

  func testEffectiveLimitClampsZeroToOne() {
    let policy = FKPhotoPickerSelectionPolicy(limit: 0)

    XCTAssertEqual(policy.effectiveLimit, 1)
  }

  func testOverflowTrimLimitUsesEffectiveLimitForFailBehavior() {
    let policy = FKPhotoPickerSelectionPolicy(limit: 5, overflowBehavior: .fail)

    XCTAssertEqual(policy.overflowTrimLimit, 5)
  }

  func testOverflowTrimLimitClampsTakeFirstLimit() {
    let policy = FKPhotoPickerSelectionPolicy(limit: 5, overflowBehavior: .takeFirst(limit: 99))

    XCTAssertEqual(policy.overflowTrimLimit, 5)
  }
}
