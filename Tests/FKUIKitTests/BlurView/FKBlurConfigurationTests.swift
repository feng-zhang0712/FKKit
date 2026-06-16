import FKUIKit
import XCTest

final class FKBlurConfigurationTests: XCTestCase {
  func testDefaultUsesDynamicSystemMaterialBackend() {
    let configuration = FKBlurConfiguration.default

    XCTAssertEqual(configuration.mode, .dynamic)
    guard case let .system(style) = configuration.backend else {
      XCTFail("Expected system backend")
      return
    }
    XCTAssertEqual(style, .systemMaterial)
    XCTAssertEqual(configuration.opacity, 1, accuracy: 0.001)
  }

  func testSystemStyleMapsToUIBlurEffectStyle() {
    XCTAssertEqual(FKBlurConfiguration.SystemStyle.dark.uiBlurEffectStyle, .dark)
    XCTAssertEqual(FKBlurConfiguration.SystemStyle.systemThinMaterial.uiBlurEffectStyle, .systemThinMaterial)
  }
}
