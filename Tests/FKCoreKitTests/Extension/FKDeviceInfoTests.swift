import FKCoreKit
import XCTest

final class FKDeviceInfoTests: XCTestCase {
  func testModelIdentifierReturnsNonEmptyHardwareString() {
    XCTAssertFalse(FKDeviceInfo.modelIdentifier().isEmpty)
  }

  @MainActor
  func testScreenScaleAndSizeReturnPositiveValues() {
    XCTAssertGreaterThan(FKDeviceInfo.screenScale(), 0)
    XCTAssertGreaterThan(FKDeviceInfo.screenSize().width, 0)
    XCTAssertGreaterThan(FKDeviceInfo.screenSize().height, 0)
  }
}
