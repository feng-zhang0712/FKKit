import FKUIKit
import XCTest

final class FKPagingNavigationBarTabOptionsTests: XCTestCase {
  func testInitClampsPreferredHeightIntoSupportedRange() {
    let low = FKPagingNavigationBarTabOptions(preferredHeight: 10)
    let high = FKPagingNavigationBarTabOptions(preferredHeight: 80)

    XCTAssertEqual(low.preferredHeight, 28, accuracy: 0.001)
    XCTAssertEqual(high.preferredHeight, 44, accuracy: 0.001)
  }

  func testInitClampsNegativeHorizontalInsetToZero() {
    let options = FKPagingNavigationBarTabOptions(horizontalInset: -8, suppressesHostTitle: false)

    XCTAssertEqual(options.horizontalInset, 0, accuracy: 0.001)
    XCTAssertFalse(options.suppressesHostTitle)
  }
}
