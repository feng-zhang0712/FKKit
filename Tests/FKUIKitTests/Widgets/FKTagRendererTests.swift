@testable import FKUIKit
import XCTest

final class FKTagRendererTests: XCTestCase {
  func testNeutralVariantUsesSecondarySystemColors() {
    let colors = FKTagRenderer.colors(for: .neutral, tintColor: .systemBlue)

    XCTAssertEqual(colors.borderWidth, 0)
    XCTAssertNil(colors.border)
  }

  func testBrandVariantUsesTintColorForeground() {
    let tint = UIColor.systemPurple
    let colors = FKTagRenderer.colors(for: .brand, tintColor: tint)

    XCTAssertTrue(colors.foreground.isEqual(tint))
  }

  func testOutlineVariantUsesSeparatorBorder() {
    let colors = FKTagRenderer.colors(for: .outline, tintColor: .systemBlue)

    XCTAssertEqual(colors.borderWidth, 1)
    XCTAssertNotNil(colors.border)
    XCTAssertTrue(colors.background.isEqual(UIColor.clear))
  }

  func testCustomVariantUsesProvidedColors() {
    let custom = FKTagCustomVariant(
      backgroundColor: .black,
      foregroundColor: .white,
      borderColor: .yellow,
      borderWidth: 2
    )
    let colors = FKTagRenderer.colors(for: .custom(custom), tintColor: .systemBlue)

    XCTAssertTrue(colors.background.isEqual(UIColor.black))
    XCTAssertTrue(colors.foreground.isEqual(UIColor.white))
    XCTAssertTrue(colors.border?.isEqual(UIColor.yellow) ?? false)
    XCTAssertEqual(colors.borderWidth, 2)
  }

  @MainActor
  func testScaledFontNeverDropsBelowMinimumCaptionSize() {
    let base = UIFont.systemFont(ofSize: 12)
    let font = FKTagRenderer.scaledFont(base: base, size: .xs)

    XCTAssertGreaterThanOrEqual(font.pointSize, 11)
  }

  @MainActor
  func testScaledFontIncreasesForLargeChipSize() {
    let base = UIFont.systemFont(ofSize: 12)
    let small = FKTagRenderer.scaledFont(base: base, size: .xs)
    let large = FKTagRenderer.scaledFont(base: base, size: .m)

    XCTAssertGreaterThan(large.pointSize, small.pointSize)
  }
}
