import FKUIKit
import XCTest

final class FKSkeletonConfigurationTests: XCTestCase {
  func testStyleGetterMapsAnimationMode() {
    var configuration = FKSkeletonConfiguration(animationMode: .shimmer)
    XCTAssertEqual(configuration.style, .gradient)

    configuration.style = .pulse
    XCTAssertEqual(configuration.animationMode, .pulse)
  }

  func testStyleSetterMapsSolidToNoneAnimationMode() {
    var configuration = FKSkeletonConfiguration()
    configuration.style = .solid
    XCTAssertEqual(configuration.animationMode, .none)
  }

  func testInitClampsNegativeGeometryAndTimingValues() {
    let configuration = FKSkeletonConfiguration(
      cornerRadius: -4,
      borderWidth: -2,
      animationDuration: 0,
      breathingMinOpacity: 2,
      defaultTextLineCount: 0,
      lineSpacing: -1,
      lineHeight: 0,
      transitionDuration: -1
    )

    XCTAssertEqual(configuration.cornerRadius, 0, accuracy: 0.001)
    XCTAssertEqual(configuration.borderWidth, 0, accuracy: 0.001)
    XCTAssertGreaterThanOrEqual(configuration.animationDuration, 0.1)
    XCTAssertEqual(configuration.breathingMinOpacity, 1, accuracy: 0.001)
    XCTAssertEqual(configuration.defaultTextLineCount, 1)
    XCTAssertEqual(configuration.lineSpacing, 0, accuracy: 0.001)
    XCTAssertGreaterThanOrEqual(configuration.lineHeight, 1)
    XCTAssertEqual(configuration.transitionDuration, 0, accuracy: 0.001)
  }
}
