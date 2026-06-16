import FKUIKit
import XCTest

final class FKStatusPillStyleTests: XCTestCase {
  func testSemanticMapsPresetStyles() {
    XCTAssertEqual(FKStatusPillStyle.success.semantic, .success)
    XCTAssertEqual(FKStatusPillStyle.warning.semantic, .warning)
    XCTAssertEqual(FKStatusPillStyle.error.semantic, .error)
    XCTAssertEqual(FKStatusPillStyle.info.semantic, .info)
    XCTAssertEqual(FKStatusPillStyle.neutral.semantic, .neutral)
    XCTAssertNil(FKStatusPillStyle.custom(.init(backgroundColor: .red, foregroundColor: .white)).semantic)
  }

  func testSizePresetResolvesHeights() {
    XCTAssertEqual(FKStatusPillSize.s.height, 28, accuracy: 0.001)
    XCTAssertEqual(FKStatusPillSize.m.height, 32, accuracy: 0.001)
  }
}
