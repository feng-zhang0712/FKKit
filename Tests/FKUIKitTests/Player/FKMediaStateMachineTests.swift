@testable import FKUIKit
import XCTest

final class FKMediaStateMachineTests: XCTestCase {
  func testAnyStateCanTransitionToFailed() {
    let states: [FKMediaPlaybackState] = [
      .idle, .preparing, .ready, .playing, .paused, .buffering, .completed,
    ]

    for state in states {
      XCTAssertTrue(
        FKMediaStateMachine.canTransition(from: state, to: .failed(.cancelled)),
        "Expected transition to failed from \(state)"
      )
    }
  }

  func testFailedCanRecoverToIdleOrPreparingOnly() {
    let failed = FKMediaPlaybackState.failed(.networkUnavailable)

    XCTAssertTrue(FKMediaStateMachine.canTransition(from: failed, to: .idle))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: failed, to: .preparing))
    XCTAssertFalse(FKMediaStateMachine.canTransition(from: failed, to: .playing))
    XCTAssertFalse(FKMediaStateMachine.canTransition(from: failed, to: .ready))
  }

  func testIdleCanBeginPreparing() {
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .idle, to: .preparing))
    XCTAssertFalse(FKMediaStateMachine.canTransition(from: .idle, to: .playing))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .idle, to: .idle))
  }

  func testPreparingCanReachReadyOrActiveStates() {
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .preparing, to: .ready))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .preparing, to: .playing))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .preparing, to: .buffering))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .preparing, to: .idle))
  }

  func testPlayingCanPauseBufferOrComplete() {
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .playing, to: .paused))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .playing, to: .buffering))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .playing, to: .completed))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .playing, to: .ready))
  }

  func testPausedCanResumeOrReprepare() {
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .paused, to: .playing))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .paused, to: .buffering))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .paused, to: .preparing))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .paused, to: .idle))
  }

  func testBufferingCanReturnToActiveStates() {
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .buffering, to: .playing))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .buffering, to: .paused))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .buffering, to: .ready))
  }

  func testCompletedCanRestartPlaybackOrReset() {
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .completed, to: .idle))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .completed, to: .preparing))
    XCTAssertTrue(FKMediaStateMachine.canTransition(from: .completed, to: .playing))
    XCTAssertFalse(FKMediaStateMachine.canTransition(from: .completed, to: .ready))
  }

  func testSameStateIsAlwaysAllowed() {
    let states: [FKMediaPlaybackState] = [
      .idle, .preparing, .ready, .playing, .paused, .buffering, .completed,
      .failed(.seekFailed),
    ]

    for state in states {
      XCTAssertTrue(
        FKMediaStateMachine.canTransition(from: state, to: state),
        "Expected identity transition for \(state)"
      )
    }
  }

  func testInvalidCrossTransitionIsRejected() {
    XCTAssertFalse(FKMediaStateMachine.canTransition(from: .idle, to: .completed))
    XCTAssertFalse(FKMediaStateMachine.canTransition(from: .completed, to: .buffering))
    XCTAssertFalse(FKMediaStateMachine.canTransition(from: .ready, to: .completed))
  }
}
