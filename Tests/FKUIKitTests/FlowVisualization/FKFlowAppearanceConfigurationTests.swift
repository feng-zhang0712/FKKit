import FKUIKit
import XCTest

final class FKFlowAppearanceConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesMediumCircularNodes() {
    let configuration = FKFlowAppearanceConfiguration()

    XCTAssertEqual(configuration.nodeSize, .medium)
    XCTAssertEqual(configuration.nodeShape, .circle)
    XCTAssertTrue(configuration.emphasizesCurrentTitle)
    XCTAssertTrue(configuration.treatsSkippedAsCompletedForConnectors)
  }

  func testAppearanceForStateReturnsConfiguredNodeAppearance() {
    let configuration = FKFlowAppearanceConfiguration()
    let completed = configuration.appearance(for: .completed)
    let expected = FKFlowAppearanceConfiguration.defaultNodeAppearances[.completed]

    XCTAssertEqual(completed.border, expected?.border)
    XCTAssertEqual(completed.iconTint, expected?.iconTint)
  }
}
