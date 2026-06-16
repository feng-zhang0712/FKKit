import FKUIKit
import XCTest

final class FKSheetAnimationConfigurationTests: XCTestCase {
  func testInitClampsDurationDampingAndResponse() {
    let configuration = FKSheetAnimationConfiguration(
      duration: -1,
      dampingRatio: 0.01,
      response: 0
    )

    XCTAssertEqual(configuration.duration, 0, accuracy: 0.001)
    XCTAssertEqual(configuration.dampingRatio, 0.1, accuracy: 0.001)
    XCTAssertEqual(configuration.response, 0.1, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesSystemLikePreset() {
    let configuration = FKSheetAnimationConfiguration()

    XCTAssertEqual(configuration.preset, .systemLike)
    XCTAssertEqual(configuration.duration, 0.32, accuracy: 0.001)
  }
}
