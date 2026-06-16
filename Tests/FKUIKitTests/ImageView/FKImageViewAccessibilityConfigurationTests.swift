import FKUIKit
import XCTest

final class FKImageViewAccessibilityConfigurationTests: XCTestCase {
  func testDefaultConfigurationIsNotDecorativeAndDoesNotAnnounceLayoutChanges() {
    let configuration = FKImageViewAccessibilityConfiguration()

    XCTAssertNil(configuration.label)
    XCTAssertNil(configuration.imageDescription)
    XCTAssertFalse(configuration.isDecorative)
    XCTAssertFalse(configuration.announcesLayoutChangeOnSuccess)
  }

  func testConfigurationStoresCustomLabelAndDecorativeFlag() {
    let configuration = FKImageViewAccessibilityConfiguration(
      label: "Product photo",
      imageDescription: "Red sneakers",
      isDecorative: true,
      announcesLayoutChangeOnSuccess: true
    )

    XCTAssertEqual(configuration.label, "Product photo")
    XCTAssertEqual(configuration.imageDescription, "Red sneakers")
    XCTAssertTrue(configuration.isDecorative)
    XCTAssertTrue(configuration.announcesLayoutChangeOnSuccess)
  }
}
