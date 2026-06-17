import FKCoreKit
import XCTest

final class FKNetworkCacheTests: XCTestCase {
  func testSetAndReadValueBeforeExpiry() {
    let cache = FKNetworkCache(namespace: "FKNetworkCacheTests.\(UUID().uuidString)")
    let payload = Data("cached-response".utf8)

    cache.set(payload, for: "users/me", ttl: 60, toDisk: false)

    XCTAssertEqual(cache.value(for: "users/me"), payload)
  }

  func testExpiredMemoryEntryReturnsNil() {
    let cache = FKNetworkCache(namespace: "FKNetworkCacheTests.\(UUID().uuidString)")
    cache.set(Data("stale".utf8), for: "stale-key", ttl: -1, toDisk: false)

    XCTAssertNil(cache.value(for: "stale-key"))
  }

  func testRemoveValueClearsMemoryEntry() {
    let cache = FKNetworkCache(namespace: "FKNetworkCacheTests.\(UUID().uuidString)")
    cache.set(Data("temp".utf8), for: "temp-key", ttl: 60, toDisk: false)

    cache.removeValue(for: "temp-key")

    XCTAssertNil(cache.value(for: "temp-key"))
  }
}
