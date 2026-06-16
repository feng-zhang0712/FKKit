import FKUIKit
import XCTest

final class FKSearchViewControllerConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesLocalFilterMode() {
    let configuration = FKSearchViewControllerConfiguration()

    XCTAssertEqual(configuration.mode, .localFilter)
    XCTAssertEqual(configuration.placement, .stickyHeader)
    XCTAssertEqual(configuration.presentation, .unified)
    XCTAssertFalse(configuration.loading.useSkeleton)
  }

  func testRemotePresetEnablesSkeletonAndSearchBarLoading() {
    let configuration = FKSearchViewControllerDefaults.remote()

    XCTAssertEqual(configuration.mode, .remote)
    XCTAssertTrue(configuration.loading.useSkeleton)
    XCTAssertTrue(configuration.loading.searchBarLoading)
  }

  func testLocalFilterPresetDisablesRemoteLoadingChrome() {
    let configuration = FKSearchViewControllerDefaults.localFilter()

    XCTAssertEqual(configuration.mode, .localFilter)
    XCTAssertFalse(configuration.loading.useSkeleton)
    XCTAssertFalse(configuration.loading.searchBarLoading)
  }
}
