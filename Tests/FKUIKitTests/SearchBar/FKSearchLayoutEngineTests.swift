@testable import FKUIKit
import UIKit
import XCTest

final class FKSearchLayoutEngineTests: XCTestCase {
  private func makeInput(
    boundsWidth: CGFloat = 320,
    showsCancelButton: Bool = false,
    isCancelVisible: Bool = false,
    showsClearButton: Bool = false,
    showsLoadingIndicator: Bool = false,
    layoutDirection: UIUserInterfaceLayoutDirection = .leftToRight
  ) -> FKSearchLayoutEngine.Input {
    var layout = FKSearchLayoutConfiguration()
    layout.growsWithDynamicType = false
    layout.minimumHeight = 44
    var appearance = FKSearchAppearanceConfiguration()
    appearance.leadingIcon.pointSize = 17
    return FKSearchLayoutEngine.Input(
      bounds: CGRect(x: 0, y: 0, width: boundsWidth, height: 0),
      layout: layout,
      appearance: appearance,
      showsCancelButton: showsCancelButton,
      isCancelVisible: isCancelVisible,
      showsClearButton: showsClearButton,
      showsLoadingIndicator: showsLoadingIndicator,
      cancelTitleSize: CGSize(width: 48, height: 20),
      layoutDirection: layoutDirection,
      scaledTextFont: appearance.textStyle.font
    )
  }

  func testMetricsUsesMinimumBarHeightWhenDynamicTypeGrowthDisabled() {
    let metrics = FKSearchLayoutEngine.metrics(for: makeInput())

    XCTAssertEqual(metrics.barHeight, 44, accuracy: 0.001)
    XCTAssertEqual(metrics.chromeFrame.height, 44, accuracy: 0.001)
  }

  func testMetricsPlacesSearchIconBeforeTextFieldForLeftToRight() {
    let metrics = FKSearchLayoutEngine.metrics(for: makeInput())

    XCTAssertFalse(metrics.searchIconFrame.isEmpty)
    XCTAssertEqual(metrics.textFieldFrame.minX, metrics.searchIconFrame.maxX + 8, accuracy: 0.001)
  }

  func testMetricsReservesCancelButtonWidthWhenVisible() {
    let hidden = FKSearchLayoutEngine.metrics(for: makeInput())
    let visible = FKSearchLayoutEngine.metrics(
      for: makeInput(showsCancelButton: true, isCancelVisible: true)
    )

    XCTAssertTrue(visible.cancelButtonFrame.width > 0)
    XCTAssertLessThan(visible.textFieldFrame.width, hidden.textFieldFrame.width)
  }

  func testMetricsShowsUnderlineForMinimalStyle() {
    var input = makeInput()
    input.layout.style = .minimal

    let metrics = FKSearchLayoutEngine.metrics(for: input)

    XCTAssertNotNil(metrics.underlineFrame)
    XCTAssertEqual(metrics.underlineFrame?.height ?? 0, 1, accuracy: 0.001)
  }

  func testResolvedCornerRadiusUsesCapsuleHalfHeightForInlineCard() {
    var layout = FKSearchLayoutConfiguration(style: .inlineCard)
    layout.growsWithDynamicType = false
    var appearance = FKSearchAppearanceConfiguration()
    appearance.cornerStyle = .capsule

    let radius = FKSearchLayoutEngine.resolvedCornerRadius(
      layout: layout,
      appearance: appearance,
      barHeight: 44
    )

    XCTAssertEqual(radius, 22, accuracy: 0.001)
  }

  func testResolvedCornerRadiusUsesFixedValueWhenConfigured() {
    var appearance = FKSearchAppearanceConfiguration()
    appearance.cornerStyle = .fixed(12)

    let radius = FKSearchLayoutEngine.resolvedCornerRadius(
      layout: FKSearchLayoutConfiguration(),
      appearance: appearance,
      barHeight: 44
    )

    XCTAssertEqual(radius, 12, accuracy: 0.001)
  }

  func testMetricsMirrorsSearchIconForRightToLeft() {
    let metrics = FKSearchLayoutEngine.metrics(for: makeInput(layoutDirection: .rightToLeft))

    XCTAssertGreaterThan(metrics.searchIconFrame.minX, metrics.textFieldFrame.maxX)
  }

  func testIntrinsicContentSizeReportsNoIntrinsicWidth() {
    var layout = FKSearchLayoutConfiguration()
    layout.growsWithDynamicType = false
    let appearance = FKSearchAppearanceConfiguration()

    let size = FKSearchLayoutEngine.intrinsicContentSize(
      layout: layout,
      appearance: appearance,
      showsCancelButton: false,
      isCancelVisible: false,
      cancelTitleSize: .zero,
      proposedWidth: 320
    )

    XCTAssertEqual(size.width, UIView.noIntrinsicMetric, accuracy: 0.001)
    XCTAssertEqual(size.height, 44, accuracy: 0.001)
  }
}
