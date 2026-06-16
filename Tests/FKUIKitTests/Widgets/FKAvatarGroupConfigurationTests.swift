import FKUIKit
import XCTest

final class FKAvatarGroupConfigurationTests: XCTestCase {
  func testInitClampsMaxVisibleToAtLeastOne() {
    let configuration = FKAvatarGroupConfiguration(maxVisible: 0)

    XCTAssertEqual(configuration.maxVisible, 1)
  }

  func testDefaultConfigurationUsesLeadingStackWithOverflowCount() {
    let configuration = FKAvatarGroupConfiguration()

    XCTAssertEqual(configuration.maxVisible, 4)
    XCTAssertTrue(configuration.showsOverflowCount)
    XCTAssertEqual(configuration.direction, .leadingToTrailing)
    XCTAssertEqual(configuration.avatarSize, .s)
  }
}
