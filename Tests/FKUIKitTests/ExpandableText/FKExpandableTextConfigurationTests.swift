import FKUIKit
import XCTest

@MainActor
final class FKExpandableTextConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesThreeLineCollapseAndInlineTailPlacement() {
    let configuration = FKExpandableText.defaultConfiguration

    if case let .lines(limit) = configuration.collapseRule {
      XCTAssertEqual(limit, 3)
    } else {
      XCTFail("Expected .lines(3) collapse rule")
    }
    XCTAssertEqual(configuration.buttonPlacement, .inlineTail)
    XCTAssertEqual(configuration.interactionMode, .buttonOnly)
    XCTAssertFalse(configuration.oneWayExpand)
  }

  func testConfigurationStoresCustomCollapseRuleAndInteractionMode() {
    let configuration = FKExpandableTextConfiguration(
      collapseRule: .noBodyTruncation,
      buttonPlacement: .trailingBottom,
      interactionMode: .fullTextArea,
      oneWayExpand: true
    )

    if case .noBodyTruncation = configuration.collapseRule {
      // expected
    } else {
      XCTFail("Expected .noBodyTruncation collapse rule")
    }
    XCTAssertEqual(configuration.buttonPlacement, .trailingBottom)
    XCTAssertEqual(configuration.interactionMode, .fullTextArea)
    XCTAssertTrue(configuration.oneWayExpand)
  }
}
