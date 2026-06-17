@testable import FKUIKit
import XCTest

final class FKThemeColorTests: XCTestCase {
  func testResolvedUsesLightVariantInLightMode() {
    let token = FKThemeColor(light: .red, dark: .blue)
    let traits = UITraitCollection(userInterfaceStyle: .light)

    let resolved = token.resolved(for: traits)
    XCTAssertTrue(FKThemeColorComparison.isEqual(resolved, UIColor.red.resolvedColor(with: traits)))
  }

  func testResolvedUsesDarkVariantInDarkMode() {
    let token = FKThemeColor(light: .red, dark: .blue)
    let traits = UITraitCollection(userInterfaceStyle: .dark)

    let resolved = token.resolved(for: traits)
    XCTAssertTrue(FKThemeColorComparison.isEqual(resolved, UIColor.blue.resolvedColor(with: traits)))
  }

  func testFixedInitializerUsesSameColorForBothModes() {
    let token = FKThemeColor(fixed: .green)
    let light = token.resolved(for: UITraitCollection(userInterfaceStyle: .light))
    let dark = token.resolved(for: UITraitCollection(userInterfaceStyle: .dark))

    XCTAssertTrue(FKThemeColorComparison.isEqual(light, dark))
  }

  func testUIColorBuilderTracksTraitChanges() {
    let token = FKThemeColor(light: .red, dark: .blue)
    let dynamic = token.uiColor()

    let light = dynamic.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    let dark = dynamic.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))

    XCTAssertTrue(FKThemeColorComparison.isEqual(light, UIColor.red.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))))
    XCTAssertTrue(FKThemeColorComparison.isEqual(dark, UIColor.blue.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))))
  }
}
