import FKUIKit
import XCTest

final class FKDividerConfigurationTests: XCTestCase {
  func testThicknessClampedToMinimumWhenNotPixelPerfect() {
    let configuration = FKDividerConfiguration(thickness: 0.1, isPixelPerfect: false)
    XCTAssertEqual(configuration.thickness, 0.5, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesHorizontalSolidHairline() {
    let configuration = FKDividerConfiguration()
    XCTAssertEqual(configuration.direction, .horizontal)
    XCTAssertEqual(configuration.lineStyle, .solid)
    XCTAssertTrue(configuration.isPixelPerfect)
    XCTAssertEqual(configuration.dashPattern, [4, 3])
  }
}
