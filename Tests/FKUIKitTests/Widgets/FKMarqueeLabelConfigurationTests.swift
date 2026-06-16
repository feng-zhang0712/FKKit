import FKUIKit
import XCTest

final class FKMarqueeLabelConfigurationTests: XCTestCase {
  func testDefaultAnimationUsesLeftDirectionAndFadeEdges() {
    let configuration = FKMarqueeLabelConfiguration()

    XCTAssertEqual(configuration.animation.direction, .left)
    XCTAssertEqual(configuration.animation.speed, 36, accuracy: 0.001)
    XCTAssertEqual(configuration.animation.fadeWidth, 16, accuracy: 0.001)
    XCTAssertTrue(configuration.interaction.pausesOnPan)
  }

  func testAnimationConfigurationStoresCustomSpeedAndGap() {
    let animation = FKMarqueeLabelAnimationConfiguration(speed: 48, loopGap: 12, fadeWidth: 8)

    XCTAssertEqual(animation.speed, 48, accuracy: 0.001)
    XCTAssertEqual(animation.loopGap, 12, accuracy: 0.001)
    XCTAssertEqual(animation.fadeWidth, 8, accuracy: 0.001)
  }
}
