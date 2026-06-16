import FKUIKit
import XCTest

final class FKAvatarSizeTests: XCTestCase {
  func testPresetDiametersMatchDocumentedValues() {
    XCTAssertEqual(FKAvatarSize.xs.diameter, 24, accuracy: 0.001)
    XCTAssertEqual(FKAvatarSize.s.diameter, 32, accuracy: 0.001)
    XCTAssertEqual(FKAvatarSize.m.diameter, 40, accuracy: 0.001)
    XCTAssertEqual(FKAvatarSize.l.diameter, 48, accuracy: 0.001)
    XCTAssertEqual(FKAvatarSize.xl.diameter, 72, accuracy: 0.001)
  }

  func testCustomDiameterClampsToMinimumSixteenPoints() {
    XCTAssertEqual(FKAvatarSize.custom(diameter: 8).diameter, 16, accuracy: 0.001)
    XCTAssertEqual(FKAvatarSize.custom(diameter: 56).diameter, 56, accuracy: 0.001)
  }
}
