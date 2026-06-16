import FKUIKit
import XCTest

final class FKRatingAppearanceConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesStarPresetAndTemplateRendering() {
    let configuration = FKRatingAppearanceConfiguration()

    XCTAssertEqual(configuration.iconStyle, .preset(.star))
    XCTAssertEqual(configuration.renderingMode, .alwaysTemplate)
    XCTAssertNotNil(configuration.symbolConfiguration)
  }

  func testConfigurationStoresCustomColorsAndIconStyle() {
    let emptyColor = UIColor.lightGray
    let filledColor = UIColor.systemPink
    let configuration = FKRatingAppearanceConfiguration(
      iconStyle: .preset(.heart),
      emptyColor: emptyColor,
      filledColor: filledColor,
      renderingMode: .alwaysOriginal
    )

    XCTAssertEqual(configuration.iconStyle, .preset(.heart))
    XCTAssertTrue(configuration.emptyColor.isEqual(emptyColor))
    XCTAssertTrue(configuration.filledColor.isEqual(filledColor))
    XCTAssertEqual(configuration.renderingMode, .alwaysOriginal)
  }
}
