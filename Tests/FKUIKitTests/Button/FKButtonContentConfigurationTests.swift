import FKUIKit
import XCTest

final class FKButtonContentConfigurationTests: XCTestCase {
  func testPresetsExposeExpectedKinds() {
    XCTAssertEqual(FKButtonContentConfiguration.textOnly.kind, .textOnly)
    XCTAssertEqual(FKButtonContentConfiguration.imageOnly.kind, .imageOnly)
    XCTAssertEqual(FKButtonContentConfiguration.custom.kind, .custom)
    XCTAssertEqual(
      FKButtonContentConfiguration.textAndImage(.leading).kind,
      .textAndImage(.leading)
    )
  }

  func testDefaultMatchesTextOnly() {
    XCTAssertEqual(FKButtonContentConfiguration.default, FKButtonContentConfiguration.textOnly)
  }
}
