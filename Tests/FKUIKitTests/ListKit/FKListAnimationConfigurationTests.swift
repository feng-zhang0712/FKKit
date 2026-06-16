import FKUIKit
import XCTest

final class FKListAnimationConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesFadeAndSkipsLoadMoreAnimation() {
    let configuration = FKListAnimationConfiguration()

    XCTAssertEqual(configuration.defaultRowAnimation, .fade)
    XCTAssertFalse(configuration.animatesLoadMoreDifferences)
    XCTAssertTrue(configuration.animatesRefreshDifferences)
  }

  func testRowAnimationMapsToUITableViewAnimation() {
    XCTAssertEqual(FKListRowAnimation.fade.tableViewAnimation, .fade)
    XCTAssertEqual(FKListRowAnimation.none.tableViewAnimation, .none)
    XCTAssertEqual(FKListRowAnimation.bottom.tableViewAnimation, .bottom)
  }
}
