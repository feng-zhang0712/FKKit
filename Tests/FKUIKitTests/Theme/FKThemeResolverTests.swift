import FKUIKit
import XCTest

final class FKThemeResolverTests: XCTestCase {
  private func makeTheme(primary: FKThemeColor) -> FKTheme {
    var colors = FKTheme.default.colors
    colors.primary = primary
    return FKTheme(
      id: "test.theme",
      colors: colors,
      typography: FKTheme.default.typography,
      metrics: FKTheme.default.metrics,
      shadows: FKTheme.default.shadows
    )
  }

  func testColorResolvesSemanticRoleFromTheme() {
    let primary = FKThemeColor(light: .red, dark: .blue)
    let theme = makeTheme(primary: primary)
    let lightTraits = UITraitCollection(userInterfaceStyle: .light)

    let resolved = FKThemeResolver.color(.primary, in: theme, traitCollection: lightTraits)
    XCTAssertTrue(resolved.cgColor.components?.first == UIColor.red.cgColor.components?.first)
  }

  func testStatusColorMapsWidgetSemanticToPalette() {
    let theme = FKTheme.default
    let traits = UITraitCollection(userInterfaceStyle: .light)

    let success = FKThemeResolver.statusColor(for: .success, in: theme, traitCollection: traits)
    let expected = theme.colors.statusSuccess.resolved(for: traits)

    XCTAssertEqual(success.cgColor, expected.cgColor)
  }

  func testFontScalesUpForAccessibilityContentSize() {
    let theme = FKTheme.default
    let regular = FKThemeResolver.font(.body, in: theme, contentSizeCategory: .medium)
    let extraLarge = FKThemeResolver.font(.body, in: theme, contentSizeCategory: .extraExtraLarge)

    XCTAssertGreaterThan(extraLarge.pointSize, regular.pointSize)
  }

  func testSurfaceColorUsesElevatedTokenWhenRequested() {
    let theme = FKTheme.default
    let traits = UITraitCollection(userInterfaceStyle: .light)

    let surface = FKThemeResolver.surfaceColor(elevated: false, in: theme, traitCollection: traits)
    let elevated = FKThemeResolver.surfaceColor(elevated: true, in: theme, traitCollection: traits)

    XCTAssertNotEqual(surface.cgColor, elevated.cgColor)
  }
}
