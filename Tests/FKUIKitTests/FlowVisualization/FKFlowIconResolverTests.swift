@testable import FKUIKit
import XCTest

final class FKFlowIconResolverTests: XCTestCase {
  func testNumberLabelUsesExplicitNumberIconValue() {
    let label = FKFlowIconResolver.numberLabel(
      for: .number(3),
      state: .current,
      stepIndex: 0
    )

    XCTAssertEqual(label, "3")
  }

  func testNumberLabelUsesOneBasedIndexForCurrentAndUpcomingWithoutIcon() {
    XCTAssertEqual(
      FKFlowIconResolver.numberLabel(for: nil, state: .current, stepIndex: 2),
      "3"
    )
    XCTAssertEqual(
      FKFlowIconResolver.numberLabel(for: nil, state: .upcoming, stepIndex: 0),
      "1"
    )
  }

  func testNumberLabelReturnsNilForCompletedWithoutExplicitNumber() {
    XCTAssertNil(
      FKFlowIconResolver.numberLabel(for: nil, state: .completed, stepIndex: 1)
    )
  }

  func testDefaultImageUsesCheckmarkForCompletedState() {
    let image = FKFlowIconResolver.image(
      for: nil,
      state: .completed,
      stepIndex: 0
    )

    XCTAssertNotNil(image)
  }

  func testDefaultImageReturnsNilForCurrentStateWithoutExplicitIcon() {
    XCTAssertNil(
      FKFlowIconResolver.image(for: nil, state: .current, stepIndex: 0)
    )
  }

  func testSystemNameIconReturnsTemplateImage() {
    let image = FKFlowIconResolver.image(
      for: .systemName("star.fill"),
      state: .upcoming,
      stepIndex: 0
    )

    XCTAssertNotNil(image)
    XCTAssertEqual(image?.renderingMode, .alwaysTemplate)
  }

  func testNumberIconReturnsNilImage() {
    XCTAssertNil(
      FKFlowIconResolver.image(for: .number(2), state: .current, stepIndex: 0)
    )
  }
}
