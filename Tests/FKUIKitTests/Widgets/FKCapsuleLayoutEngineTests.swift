@testable import FKUIKit
import XCTest

final class FKCapsuleLayoutEngineTests: XCTestCase {
  private func makeInput(
    title: String = "Label",
    hasLeadingIcon: Bool = false,
    showsRemoveButton: Bool = false,
    maxWidth: CGFloat? = nil
  ) -> FKCapsuleLayoutEngine.Input {
    FKCapsuleLayoutEngine.Input(
      title: title,
      font: UIFont.systemFont(ofSize: 14, weight: .medium),
      height: 32,
      horizontalPadding: 12,
      iconSpacing: 6,
      leadingIconPointSize: 16,
      hasLeadingIcon: hasLeadingIcon,
      showsRemoveButton: showsRemoveButton,
      removeSymbolPointSize: 12,
      removeHitSide: 44,
      maxWidth: maxWidth
    )
  }

  func testLayoutUsesHalfHeightCornerRadius() {
    let metrics = FKCapsuleLayoutEngine.layout(makeInput())

    XCTAssertEqual(metrics.cornerRadius, 16, accuracy: 0.001)
    XCTAssertEqual(metrics.size.height, 32, accuracy: 0.001)
  }

  func testLayoutIncludesLeadingIconFrameWhenRequested() {
    let metrics = FKCapsuleLayoutEngine.layout(makeInput(hasLeadingIcon: true))

    XCTAssertNotNil(metrics.leadingIconFrame)
    XCTAssertEqual(metrics.leadingIconFrame!.minX, 12, accuracy: 0.001)
    XCTAssertGreaterThan(metrics.titleFrame.minX, metrics.leadingIconFrame!.maxX)
  }

  func testLayoutCapsWidthWhenMaxWidthProvided() {
    let metrics = FKCapsuleLayoutEngine.layout(
      makeInput(title: "A very long chip title that should wrap or truncate", maxWidth: 120)
    )

    XCTAssertLessThanOrEqual(metrics.size.width, 120 + 0.001)
  }

  func testRemoveHitAreaStaysInTrailingGutterWithoutOverlappingTitle() {
    let metrics = FKCapsuleLayoutEngine.layout(makeInput(showsRemoveButton: true))

    XCTAssertNotNil(metrics.removeButtonFrame)
    XCTAssertNotNil(metrics.removeHitAreaFrame)
    XCTAssertGreaterThanOrEqual(metrics.removeHitAreaFrame!.minX, metrics.titleFrame.maxX - 0.001)
    XCTAssertLessThanOrEqual(metrics.removeHitAreaFrame!.maxX, metrics.size.width - 12 + 0.001)
  }

  func testPillFrameAlignsLeadingInLeftToRightLayout() {
    let metrics = FKCapsuleLayoutEngine.layout(makeInput())
    let bounds = CGRect(x: 0, y: 0, width: 200, height: 44)

    let frame = FKCapsuleLayoutEngine.pillFrame(
      metrics: metrics,
      in: bounds,
      layoutDirection: .leftToRight
    )

    XCTAssertEqual(frame.minX, 0, accuracy: 0.001)
    XCTAssertEqual(frame.midY, bounds.midY, accuracy: 0.001)
  }

  func testPillFrameAlignsTrailingInRightToLeftLayout() {
    let metrics = FKCapsuleLayoutEngine.layout(makeInput())
    let bounds = CGRect(x: 0, y: 0, width: 200, height: 44)

    let frame = FKCapsuleLayoutEngine.pillFrame(
      metrics: metrics,
      in: bounds,
      layoutDirection: .rightToLeft
    )

    XCTAssertEqual(frame.maxX, bounds.maxX, accuracy: 0.001)
  }
}
