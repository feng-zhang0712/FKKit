import FKUIKit
import XCTest

final class FKTextFieldAccessibilityConfigurationTests: XCTestCase {
  func testInitClampsMinimumHitTargetToTwentyEightPoints() {
    let configuration = FKTextFieldAccessibilityConfiguration(minimumHitTarget: 10)

    XCTAssertEqual(configuration.minimumHitTarget, 28, accuracy: 0.001)
  }

  func testDefaultConfigurationAnnouncesStatusButNotCounterChanges() {
    let configuration = FKTextFieldAccessibilityConfiguration()

    XCTAssertTrue(configuration.announcesStatusChanges)
    XCTAssertFalse(configuration.announcesCounterChanges)
    XCTAssertEqual(configuration.minimumHitTarget, 44, accuracy: 0.001)
  }
}
