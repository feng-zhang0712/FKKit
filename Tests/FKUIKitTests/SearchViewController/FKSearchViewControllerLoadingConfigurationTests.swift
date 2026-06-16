import FKUIKit
import XCTest

final class FKSearchViewControllerLoadingConfigurationTests: XCTestCase {
  func testInitClampsSkeletonRowCountToAtLeastOne() {
    let configuration = FKSearchViewControllerLoadingConfiguration(skeletonRowCount: 0)

    XCTAssertEqual(configuration.skeletonRowCount, 1)
  }

  func testDefaultConfigurationEnablesSearchBarLoading() {
    let configuration = FKSearchViewControllerLoadingConfiguration()

    XCTAssertFalse(configuration.useSkeleton)
    XCTAssertTrue(configuration.searchBarLoading)
  }
}
