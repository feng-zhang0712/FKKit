import FKUIKit
import XCTest

final class FKTabBarBadgeConfigurationTests: XCTestCase {
  func testResolvedPrefersDisabledThenSelectedThenNormal() {
    let configuration = FKTabBarBadgeStateConfiguration(
      normal: .count(1),
      selected: .count(2),
      disabled: .dot
    )

    XCTAssertEqual(configuration.resolved(isSelected: false, isEnabled: true), .count(1))
    XCTAssertEqual(configuration.resolved(isSelected: true, isEnabled: true), .count(2))
    XCTAssertEqual(configuration.resolved(isSelected: true, isEnabled: false), .dot)
  }

  func testConvenienceFactoriesBuildExpectedContent() {
    XCTAssertEqual(FKTabBarBadgeConfiguration.dot.state.normal, .dot)
    XCTAssertEqual(FKTabBarBadgeConfiguration.count(5).state.normal, .count(5))
    XCTAssertEqual(FKTabBarBadgeConfiguration.text("NEW").state.normal, .text("NEW"))
    XCTAssertEqual(FKTabBarBadgeConfiguration.custom(id: "vip").state.normal, .custom(id: "vip"))
  }
}
