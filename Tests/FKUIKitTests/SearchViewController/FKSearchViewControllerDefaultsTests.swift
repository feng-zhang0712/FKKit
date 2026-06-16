import FKUIKit
import XCTest

@MainActor
final class FKSearchViewControllerDefaultsTests: XCTestCase {
  func testLocalFilterPresetUsesLocalModeWithoutSkeletonLoading() {
    let configuration = FKSearchViewControllerDefaults.localFilter()

    XCTAssertEqual(configuration.mode, .localFilter)
    XCTAssertFalse(configuration.loading.useSkeleton)
    XCTAssertFalse(configuration.loading.searchBarLoading)
  }

  func testRemotePresetEnablesSkeletonAndSearchBarLoading() {
    let configuration = FKSearchViewControllerDefaults.remote()

    XCTAssertEqual(configuration.mode, .remote)
    XCTAssertTrue(configuration.loading.useSkeleton)
    XCTAssertTrue(configuration.loading.searchBarLoading)
  }
}
