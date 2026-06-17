import FKUIKit
import XCTest

final class FKMediaQoEServiceTests: XCTestCase {
  func testStallAndErrorEventsUpdateSnapshot() {
    let service = FKMediaQoEService()
    let mediaError = FKMediaError.networkUnavailable

    service.track(event: .stall(itemID: "clip"))
    service.track(event: .error(itemID: "clip", error: mediaError))

    let snapshot = service.currentSnapshot()
    XCTAssertEqual(snapshot.stallCount, 1)
    XCTAssertEqual(snapshot.errorCount, 1)
    XCTAssertEqual(snapshot.lastError, mediaError)
  }

  func testPauseAfterPlayAccumulatesPlayTime() {
    let service = FKMediaQoEService()
    service.track(event: .play(itemID: "clip"))
    Thread.sleep(forTimeInterval: 0.05)
    service.track(event: .pause(itemID: "clip"))

    XCTAssertGreaterThan(service.currentSnapshot().totalPlaySeconds, 0)
  }

  func testCompleteAccumulatesPlayTimeLikePause() {
    let service = FKMediaQoEService()
    service.track(event: .play(itemID: "clip"))
    Thread.sleep(forTimeInterval: 0.05)
    service.track(event: .complete(itemID: "clip"))

    XCTAssertGreaterThan(service.currentSnapshot().totalPlaySeconds, 0)
  }

  func testResetClearsSnapshot() {
    let service = FKMediaQoEService()
    service.track(event: .stall(itemID: "clip"))
    service.track(event: .error(itemID: "clip", error: .cancelled))
    service.reset()

    let snapshot = service.currentSnapshot()
    XCTAssertEqual(snapshot.stallCount, 0)
    XCTAssertEqual(snapshot.errorCount, 0)
    XCTAssertNil(snapshot.lastError)
    XCTAssertEqual(snapshot.totalPlaySeconds, 0)
  }
}
