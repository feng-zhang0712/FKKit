import FKUIKit
import XCTest

final class FKAlertPresentationConfigurationTests: XCTestCase {
  func testDefaultConfigurationDisablesBackdropAndSwipeDismiss() {
    let configuration = FKAlertPresentationConfiguration()

    XCTAssertNil(configuration.sheet)
    XCTAssertFalse(configuration.allowsBackdropTapToDismiss)
    XCTAssertFalse(configuration.allowsSwipeToDismiss)
    XCTAssertNil(configuration.cornerRadius)
  }

  func testConfigurationStoresCustomDismissFlagsAndCornerRadius() {
    let configuration = FKAlertPresentationConfiguration(
      allowsBackdropTapToDismiss: true,
      allowsSwipeToDismiss: true,
      cornerRadius: 16
    )

    XCTAssertTrue(configuration.allowsBackdropTapToDismiss)
    XCTAssertTrue(configuration.allowsSwipeToDismiss)
    XCTAssertEqual(configuration.cornerRadius, CGFloat(16))
  }
}
