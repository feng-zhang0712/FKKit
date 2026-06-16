import FKUIKit
import XCTest

final class FKMediaPlaybackStateTests: XCTestCase {
  func testIsActiveReturnsTrueForPlayingAndBuffering() {
    XCTAssertTrue(FKMediaPlaybackState.playing.isActive)
    XCTAssertTrue(FKMediaPlaybackState.buffering.isActive)
  }

  func testIsActiveReturnsFalseForTerminalAndIdleStates() {
    let inactiveStates: [FKMediaPlaybackState] = [
      .idle,
      .preparing,
      .ready,
      .paused,
      .completed,
      .failed(.cancelled),
    ]

    for state in inactiveStates {
      XCTAssertFalse(state.isActive, "Expected inactive for \(state)")
    }
  }

  func testIsFailedReturnsTrueOnlyForFailedCase() {
    XCTAssertTrue(FKMediaPlaybackState.failed(.networkUnavailable).isFailed)
    XCTAssertFalse(FKMediaPlaybackState.playing.isFailed)
    XCTAssertFalse(FKMediaPlaybackState.completed.isFailed)
  }

  func testFailedStatePreservesAssociatedError() {
    let state = FKMediaPlaybackState.failed(.seekFailed)
    guard case let .failed(error) = state else {
      XCTFail("Expected failed case")
      return
    }
    XCTAssertEqual(error, .seekFailed)
  }
}
