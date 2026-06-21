@testable import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKPagingScrollUtilitiesTests: FKUIKitTestCase {
  func testHorizontalScrollViewsFindsWideEnabledScrollView() {
    let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
    let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
    scrollView.contentSize = CGSize(width: 600, height: 100)
    scrollView.isScrollEnabled = true
    root.addSubview(scrollView)

    let results = FKPagingScrollUtilities.horizontalScrollViews(in: root)

    XCTAssertEqual(results.count, 1)
    XCTAssertTrue(results.first === scrollView)
  }

  func testHorizontalScrollViewsIgnoresNarrowContentSize() {
    let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
    let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
    scrollView.contentSize = CGSize(width: 300, height: 100)
    scrollView.isScrollEnabled = true
    root.addSubview(scrollView)

    XCTAssertTrue(FKPagingScrollUtilities.horizontalScrollViews(in: root).isEmpty)
  }

  func testHorizontalScrollViewsFindsNestedScrollViews() {
    let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
    let container = UIView(frame: root.bounds)
    let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 300, height: 80))
    scrollView.contentSize = CGSize(width: 500, height: 80)
    scrollView.isScrollEnabled = true
    container.addSubview(scrollView)
    root.addSubview(container)

    XCTAssertEqual(FKPagingScrollUtilities.horizontalScrollViews(in: root).count, 1)
  }

  func testDetachFromParentIfNeededRemovesChildController() {
    let parent = UIViewController()
    let child = UIViewController()
    parent.addChild(child)
    parent.view.addSubview(child.view)
    child.didMove(toParent: parent)

    FKPagingScrollUtilities.detachFromParentIfNeeded(child)

    XCTAssertNil(child.parent)
    XCTAssertNil(child.view.superview)
  }

  func testDetachFromParentIfNeededIsNoOpWithoutParent() {
    let controller = UIViewController()

    FKPagingScrollUtilities.detachFromParentIfNeeded(controller)

    XCTAssertNil(controller.parent)
  }

  func testScrollPageToTopScrollsNestedTableViewToFirstRow() {
    let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    let tableView = UITableView(frame: root.bounds)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    root.addSubview(tableView)
    tableView.reloadData()
    tableView.layoutIfNeeded()
    tableView.setContentOffset(CGPoint(x: 0, y: 200), animated: false)

    FKPagingScrollUtilities.scrollPageToTop(in: root)

    let expectation = expectation(description: "scroll completes")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      XCTAssertLessThan(tableView.contentOffset.y, 200)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1)
  }
}
