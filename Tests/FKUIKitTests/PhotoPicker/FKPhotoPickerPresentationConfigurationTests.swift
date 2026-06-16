import FKUIKit
import XCTest

final class FKPhotoPickerPresentationConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesAutomaticPresentationStyle() {
    let configuration = FKPhotoPickerPresentationConfiguration()

    XCTAssertEqual(configuration.style, .automatic)
  }

  func testConfigurationStoresCustomPresentationStyle() {
    let configuration = FKPhotoPickerPresentationConfiguration(style: .pageSheet)

    XCTAssertEqual(configuration.style, .pageSheet)
  }
}
