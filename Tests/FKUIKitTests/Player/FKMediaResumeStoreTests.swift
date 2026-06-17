import FKUIKit
import XCTest

final class FKMediaResumeStoreTests: XCTestCase {
  func testInMemoryStoreRoundTripAndRemoval() {
    let store = FKMediaInMemoryResumeStore()

    store.setPosition(42.5, for: "episode-1")
    XCTAssertEqual(store.position(for: "episode-1"), 42.5)
    XCTAssertNil(store.position(for: "missing"))

    store.removePosition(for: "episode-1")
    XCTAssertNil(store.position(for: "episode-1"))
  }

  func testUserDefaultsStorePersistsAcrossInstances() {
    let suiteName = "FKMediaResumeStoreTests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
      return XCTFail("Failed to create UserDefaults suite")
    }
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let prefix = "test."
    let first = FKMediaUserDefaultsResumeStore(defaults: defaults, keyPrefix: prefix)
    first.setPosition(12.0, for: "track-a")

    let second = FKMediaUserDefaultsResumeStore(defaults: defaults, keyPrefix: prefix)
    XCTAssertEqual(second.position(for: "track-a"), 12.0)

    second.removePosition(for: "track-a")
    XCTAssertNil(first.position(for: "track-a"))
  }
}
