@testable import FKUIKit
import XCTest

@MainActor
final class FKRefreshCoordinatorTests: FKUIKitTestCase {
  private var coordinator: FKRefreshCoordinator!

  override func setUp() {
    super.setUp()
    coordinator = FKRefreshCoordinator()
  }

  override func tearDown() {
    coordinator = nil
    super.tearDown()
  }

  func testCanStartAllowsParallelConcurrencyRegardlessOfRunningWork() {
    coordinator.policy = FKRefreshPolicy(concurrency: .parallel)
    coordinator.didStart(kind: .pullToRefresh)

    XCTAssertTrue(coordinator.canStart(kind: .loadMore))
  }

  func testCanStartBlocksWhenMutuallyExclusiveAndWorkIsRunning() {
    coordinator.policy = FKRefreshPolicy(concurrency: .mutuallyExclusive)
    coordinator.didStart(kind: .pullToRefresh)

    XCTAssertFalse(coordinator.canStart(kind: .loadMore))
  }

  func testCanStartQueuesSecondKindWhenQueueingPolicyIsActive() {
    coordinator.policy = FKRefreshPolicy(concurrency: .queueing)
    coordinator.didStart(kind: .pullToRefresh)

    XCTAssertFalse(coordinator.canStart(kind: .loadMore))
  }

  func testDidCompleteAllowsQueuedKindAfterRunningWorkEnds() {
    coordinator.policy = FKRefreshPolicy(concurrency: .queueing)
    coordinator.didStart(kind: .pullToRefresh)
    _ = coordinator.canStart(kind: .loadMore)

    coordinator.didComplete(kind: .pullToRefresh, isTerminal: true)

    XCTAssertTrue(coordinator.canStart(kind: .loadMore))
  }
}
