import FKCoreKit
import XCTest

final class DecimalExtensionTests: XCTestCase {
  func testDoubleValueBridgesThroughNSDecimalNumber() {
    let value = Decimal(string: "12.5")!

    XCTAssertEqual(value.fk_doubleValue, 12.5, accuracy: 0.001)
  }

  func testRoundedAppliesScaleAndRoundingMode() {
    let value = Decimal(string: "1.236")!

    XCTAssertEqual(value.fk_rounded(scale: 2, mode: .down), Decimal(string: "1.23"))
  }
}
