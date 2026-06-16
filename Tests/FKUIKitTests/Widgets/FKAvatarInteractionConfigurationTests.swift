import FKUIKit
import XCTest

final class FKAvatarInteractionConfigurationTests: XCTestCase {
  func testInitClampsHighlightScaleIntoSupportedRange() {
    let tooSmall = FKAvatarInteractionConfiguration(highlightScale: 0.5)
    let tooLarge = FKAvatarInteractionConfiguration(highlightScale: 1.2)

    XCTAssertEqual(tooSmall.highlightScale, 0.8, accuracy: 0.001)
    XCTAssertEqual(tooLarge.highlightScale, 1, accuracy: 0.001)
  }

  func testDefaultConfigurationExpandsHitAreaAndRetriesOnFailure() {
    let configuration = FKAvatarInteractionConfiguration()

    XCTAssertTrue(configuration.expandsHitAreaToMinimumSize)
    XCTAssertTrue(configuration.highlightsOnPress)
    XCTAssertTrue(configuration.retriesOnFailure)
  }
}
