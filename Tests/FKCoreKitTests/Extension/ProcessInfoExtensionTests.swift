import FKCoreKit
import XCTest

final class ProcessInfoExtensionTests: XCTestCase {
  func testThermalStateDescriptionMapsKnownStates() {
    let description = ProcessInfo.processInfo.fk_thermalStateDescription

    XCTAssertFalse(description.isEmpty)
    XCTAssertNotEqual(description, "unknown")
  }

  func testIsRunningInPreviewIsFalseInUnitTests() {
    XCTAssertFalse(ProcessInfo.processInfo.fk_isRunningInPreview)
  }
}
