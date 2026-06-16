import FKUIKit
import XCTest

final class FKListSearchConfigurationTests: XCTestCase {
  func testDefaultConfigurationClearsSelectionAndUsesNoSearchResultScenario() {
    let configuration = FKListSearchConfiguration()

    XCTAssertTrue(configuration.clearsSelectionOnSearch)
    XCTAssertEqual(configuration.emptyScenario, .noSearchResult)
  }

  func testConfigurationStoresCustomEmptyScenario() {
    let configuration = FKListSearchConfiguration(
      clearsSelectionOnSearch: false,
      emptyScenario: .noFavorites
    )

    XCTAssertFalse(configuration.clearsSelectionOnSearch)
    XCTAssertEqual(configuration.emptyScenario, .noFavorites)
  }
}
