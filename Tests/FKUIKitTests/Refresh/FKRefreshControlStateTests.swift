import FKUIKit
import XCTest

@MainActor
final class FKRefreshControlStateTests: FKUIKitTestCase {
  private var scrollView: UIScrollView!

  override func setUp() {
    super.setUp()
    scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    scrollView.contentSize = CGSize(width: 320, height: 900)
  }

  override func tearDown() {
    scrollView = nil
    super.tearDown()
  }

  private func silentPullConfiguration() -> FKRefreshConfiguration {
    var configuration = FKRefreshConfiguration.default
    configuration.isSilentRefresh = true
    configuration.finishedHoldDuration = 0
    return configuration
  }

  func testBeginRefreshingTransitionsToRefreshingForSilentHeader() {
    let control = scrollView.fk_addPullToRefresh(configuration: silentPullConfiguration()) {}
    control.beginRefreshing()

    XCTAssertEqual(control.state, .refreshing)
  }

  func testEndRefreshingTransitionsHeaderToFinished() {
    let control = scrollView.fk_addPullToRefresh(configuration: silentPullConfiguration()) {}
    control.beginRefreshing()
    control.endRefreshing()

    if case .finished = control.state {
      // expected terminal success state before collapse animation
    } else {
      XCTFail("Expected finished, got \(control.state)")
    }
  }

  func testBeginLoadingMoreTransitionsFooterToLoadingMore() {
    let control = scrollView.fk_addLoadMore {}
    control.beginLoadingMore()

    if case .loadingMore = control.state {
      // expected
    } else {
      XCTFail("Expected loadingMore, got \(control.state)")
    }
  }

  func testEndRefreshingWithNoMoreDataKeepsFooterInNoMoreDataState() {
    let control = scrollView.fk_addLoadMore {}
    control.beginLoadingMore()
    control.endRefreshingWithNoMoreData()

    if case .noMoreData = control.state {
      // expected
    } else {
      XCTFail("Expected noMoreData, got \(control.state)")
    }
  }

  func testStaleActionTokenIsIgnoredWhenEndingRefresh() {
    var capturedToken: UInt64?
    let control = scrollView.fk_addPullToRefresh(configuration: silentPullConfiguration()) { context in
      capturedToken = context.token
    }

    control.beginRefreshing()
    XCTAssertNotNil(capturedToken)

    control.endRefreshing(token: (capturedToken ?? 0) &+ 1)
    XCTAssertEqual(control.state, .refreshing)

    control.endRefreshing(token: capturedToken)
    if case .finished = control.state {
      // expected
    } else {
      XCTFail("Expected finished after valid token, got \(control.state)")
    }
  }

  func testLoadMoreReArmsAutoTriggerAfterFastSuccessfulCompletion() async {
    var configuration = FKRefreshConfiguration.default
    configuration.finishedHoldDuration = 0
    configuration.minimumLoadingVisibilityDuration = 0
    configuration.loadMorePreloadOffset = 0
    configuration.triggerThreshold = 10
    configuration.autohidesFooterWhenNotScrollable = false

    scrollView.contentSize = CGSize(width: 320, height: 1200)
    scrollView.bounds = CGRect(x: 0, y: 0, width: 320, height: 480)

    let loadCount = RefreshLoadCounter()
    var control: FKRefreshControl!
    control = scrollView.fk_addLoadMore(configuration: configuration) {
      loadCount.increment()
      control.endRefreshing()
    }
    scrollView.layoutIfNeeded()

    let bottomOffset = max(
      0,
      scrollView.contentSize.height
        - scrollView.bounds.height
        + scrollView.adjustedContentInset.bottom
    )

    scrollView.contentOffset = CGPoint(x: 0, y: bottomOffset)
    try? await Task.sleep(nanoseconds: 150_000_000)
    XCTAssertEqual(loadCount.value, 1)

    scrollView.contentOffset = CGPoint(x: 0, y: bottomOffset - 5)
    scrollView.contentOffset = CGPoint(x: 0, y: bottomOffset)
    try? await Task.sleep(nanoseconds: 150_000_000)

    XCTAssertEqual(loadCount.value, 2)
  }

  func testLoadMoreDoesNotReArmAutoTriggerAfterFailure() async {
    var configuration = FKRefreshConfiguration.default
    configuration.finishedHoldDuration = 0
    configuration.minimumLoadingVisibilityDuration = 0
    configuration.loadMorePreloadOffset = 0
    configuration.triggerThreshold = 10
    configuration.autohidesFooterWhenNotScrollable = false

    scrollView.contentSize = CGSize(width: 320, height: 1200)
    scrollView.bounds = CGRect(x: 0, y: 0, width: 320, height: 480)

    let loadCount = RefreshLoadCounter()
    var control: FKRefreshControl!
    control = scrollView.fk_addLoadMore(configuration: configuration) {
      loadCount.increment()
      control.endRefreshingWithError(NSError(domain: "test", code: 1))
    }
    scrollView.layoutIfNeeded()

    let bottomOffset = max(
      0,
      scrollView.contentSize.height
        - scrollView.bounds.height
        + scrollView.adjustedContentInset.bottom
    )

    scrollView.contentOffset = CGPoint(x: 0, y: bottomOffset)
    try? await Task.sleep(nanoseconds: 150_000_000)
    XCTAssertEqual(loadCount.value, 1)

    scrollView.contentOffset = CGPoint(x: 0, y: bottomOffset - 5)
    scrollView.contentOffset = CGPoint(x: 0, y: bottomOffset)
    try? await Task.sleep(nanoseconds: 150_000_000)

    XCTAssertEqual(loadCount.value, 1)
    if case .failed = control.state {
      // expected
    } else {
      XCTFail("Expected failed state, got \(control.state)")
    }
  }
}

private final class RefreshLoadCounter: @unchecked Sendable {
  private let lock = NSLock()
  private(set) var value = 0

  func increment() {
    lock.lock()
    value += 1
    lock.unlock()
  }
}
