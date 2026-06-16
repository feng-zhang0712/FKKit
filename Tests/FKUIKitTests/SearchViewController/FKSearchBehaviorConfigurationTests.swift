import FKUIKit
import XCTest

final class FKSearchBehaviorConfigurationTests: XCTestCase {
  func testDefaultConfigurationRestoresBaselineAndCancelsOnDisappear() {
    let configuration = FKSearchBehaviorConfiguration()

    XCTAssertTrue(configuration.cancelRestoresBaseline)
    XCTAssertTrue(configuration.cancelsOnDisappear)
    XCTAssertTrue(configuration.animatesSnapshotChanges)
    XCTAssertFalse(configuration.showsResultsOnEmptyQuery)
    XCTAssertFalse(configuration.focusesSearchOnAppear)
  }

  func testConfigurationStoresCustomRemoteEmptyQueryBehavior() {
    let configuration = FKSearchBehaviorConfiguration(
      showsResultsOnEmptyQuery: true,
      focusesSearchOnAppear: true
    )

    XCTAssertTrue(configuration.showsResultsOnEmptyQuery)
    XCTAssertTrue(configuration.focusesSearchOnAppear)
  }
}
