@testable import FKUIKit
import XCTest

@MainActor
final class FKPagingPageStoreTests: XCTestCase {
  func testEagerModeReturnsControllersByIndex() {
    let first = UIViewController()
    let second = UIViewController()
    let store = FKPagingPageStore(viewControllers: [first, second])

    XCTAssertTrue(store.isEagerMode)
    XCTAssertEqual(store.pageCount, 2)
    XCTAssertIdentical(store.controller(at: 0), first)
    XCTAssertIdentical(store.controller(at: 1), second)
    XCTAssertNil(store.controller(at: 2))
  }

  func testLazyModeCreatesAndCachesControllers() {
    var creationCount = 0
    let store = FKPagingPageStore(pageCount: 3) { index in
      creationCount += 1
      return UIViewController(named: "page-\(index)")
    }

    XCTAssertFalse(store.isEagerMode)
    _ = store.controller(at: 0)
    _ = store.controller(at: 0)

    XCTAssertEqual(creationCount, 1)
    XCTAssertIdentical(store.controller(at: 0), store.cachedController(at: 0))
  }

  func testIndexOfReturnsMappedControllerIndex() {
    let first = UIViewController()
    let second = UIViewController()
    let store = FKPagingPageStore(viewControllers: [first, second])

    XCTAssertEqual(store.index(of: second), 1)
  }

  func testPreloadMaterializesControllersInRange() {
    var createdIndices: [Int] = []
    let store = FKPagingPageStore(pageCount: 5) { index in
      createdIndices.append(index)
      return UIViewController()
    }

    store.preload(around: 2, range: 1)

    XCTAssertEqual(Set(createdIndices), Set([1, 2, 3]))
  }

  func testCompactCacheEvictsPagesOutsideRetentionWindow() {
    var evictedIndices: [Int] = []
    let store = FKPagingPageStore(pageCount: 5) { _ in UIViewController() }

    store.preload(around: 2, range: 2)
    store.compactCache(selectedIndex: 2, retention: .keepNear(distance: 1)) { index, _ in
      evictedIndices.append(index)
    }

    XCTAssertTrue(evictedIndices.contains(0))
    XCTAssertTrue(evictedIndices.contains(4))
    XCTAssertNotNil(store.cachedController(at: 2))
    XCTAssertNil(store.cachedController(at: 0))
  }

  func testSyncPageCountShrinksEagerControllersAndInvokesEviction() {
    let first = UIViewController()
    let second = UIViewController()
    let store = FKPagingPageStore(viewControllers: [first, second])
    var evicted: [Int] = []

    store.syncPageCount(1) { index, _ in
      evicted.append(index)
    }

    XCTAssertEqual(store.pageCount, 1)
    XCTAssertEqual(evicted, [1])
    XCTAssertIdentical(store.controller(at: 0), first)
  }

  func testInvalidatePageRemovesLazyCachedController() {
    let store = FKPagingPageStore(pageCount: 2) { _ in UIViewController() }
    _ = store.controller(at: 0)

    let removed = store.invalidatePage(at: 0)

    XCTAssertNotNil(removed)
    XCTAssertNil(store.cachedController(at: 0))
  }
}

private extension UIViewController {
  convenience init(named name: String) {
    self.init(nibName: nil, bundle: nil)
    self.title = name
  }
}
