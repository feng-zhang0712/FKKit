import FKUIKit
import XCTest

final class FKAvatarLayoutConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesMediumCircleAvatar() {
    let configuration = FKAvatarLayoutConfiguration()

    XCTAssertEqual(configuration.size, .m)
    XCTAssertEqual(configuration.shape, .circle)
  }

  func testConfigurationStoresCustomSizeAndShape() {
    let configuration = FKAvatarLayoutConfiguration(size: .l, shape: .roundedRectangle(cornerRadius: 8))

    XCTAssertEqual(configuration.size, .l)
    if case .roundedRectangle(let cornerRadius) = configuration.shape {
      XCTAssertEqual(cornerRadius, 8, accuracy: 0.001)
    } else {
      XCTFail("Expected roundedRectangle shape")
    }
  }
}
