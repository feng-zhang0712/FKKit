import FKUIKit
import XCTest

final class FKIconViewConfigurationTests: XCTestCase {
  func testIconViewSizeResolvesContainerAndSymbolMetrics() {
    XCTAssertEqual(FKIconViewSize.s.side, 24, accuracy: 0.001)
    XCTAssertEqual(FKIconViewSize.m.symbolPointSize, 15, accuracy: 0.001)
    XCTAssertEqual(FKIconViewSize.l.side, 32, accuracy: 0.001)
  }

  func testConfigurationEqualityComparesLayoutAndAccessibility() {
    let first = FKIconViewConfiguration(
      layout: FKIconViewLayoutConfiguration(size: .l, emptyContentBehavior: .placeholder),
      accessibility: FKIconViewAccessibilityConfiguration(isDecorative: false, customLabel: "Settings")
    )
    let matching = FKIconViewConfiguration(
      layout: FKIconViewLayoutConfiguration(size: .l, emptyContentBehavior: .placeholder),
      accessibility: FKIconViewAccessibilityConfiguration(isDecorative: false, customLabel: "Settings")
    )
    let different = FKIconViewConfiguration(
      accessibility: FKIconViewAccessibilityConfiguration(customLabel: "Home")
    )

    XCTAssertEqual(first, matching)
    XCTAssertNotEqual(first, different)
  }
}
