import FKUIKit
import XCTest

final class FKProgressBarLayoutConfigurationTests: XCTestCase {
  func testInitClampsTrackThicknessAndSegmentGapFraction() {
    let configuration = FKProgressBarLayoutConfiguration(
      trackThickness: 0,
      segmentGapFraction: 0.9
    )

    XCTAssertEqual(configuration.trackThickness, 0.5, accuracy: 0.001)
    XCTAssertEqual(configuration.segmentGapFraction, 0.45, accuracy: 0.001)
  }

  func testInitClampsRingDiameterToMinimumSize() {
    let configuration = FKProgressBarLayoutConfiguration(ringDiameter: 4)

    XCTAssertNotNil(configuration.ringDiameter)
    XCTAssertEqual(Double(configuration.ringDiameter!), 8, accuracy: 0.001)
  }
}
