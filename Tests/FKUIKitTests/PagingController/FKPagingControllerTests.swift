import FKUIKit
import XCTest

@MainActor
final class FKPagingControllerTests: FKUIKitTestCase {
  private var window: UIWindow!

  override func setUp() {
    super.setUp()
    window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
    window.makeKeyAndVisible()
  }

  override func tearDown() {
    window.isHidden = true
    window = nil
    super.tearDown()
  }

  func testCommitPageSwitchUpdatesSelectedIndex() {
    let tabs = [FKTabBarItem(id: "tab-0"), FKTabBarItem(id: "tab-1")]
    let pages = [UIViewController(), UIViewController()]
    let paging = FKPagingController(tabs: tabs, viewControllers: pages, selectedIndex: 0)
    window.rootViewController = paging
    paging.loadViewIfNeeded()
    paging.view.layoutIfNeeded()

    paging.commitPageSwitch(to: 1, animated: false)

    XCTAssertEqual(paging.selectedIndex, 1)
    XCTAssertEqual(paging.stateSnapshot.selectedIndex, 1)
    XCTAssertEqual(paging.stateSnapshot.phase, .idle)
  }

  func testSetSelectedIndexForItemIDReturnsFalseWhenIDIsMissing() {
    let tabs = [FKTabBarItem(id: "only")]
    let paging = FKPagingController(tabs: tabs, viewControllers: [UIViewController()], selectedIndex: 0)
    window.rootViewController = paging
    paging.loadViewIfNeeded()

    XCTAssertFalse(paging.setSelectedIndex(forItemID: "missing-tab", animated: false))
    XCTAssertEqual(paging.selectedIndex, 0)
  }
}
