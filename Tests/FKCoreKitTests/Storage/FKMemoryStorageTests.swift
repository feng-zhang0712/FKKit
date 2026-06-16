import FKCoreKit
import XCTest

final class FKMemoryStorageTests: XCTestCase {
  private var storage: FKMemoryStorage!

  override func setUp() {
    super.setUp()
    storage = FKMemoryStorage()
  }

  override func tearDown() {
    storage = nil
    super.tearDown()
  }

  func testSetAndValueRoundTrip() throws {
    try storage.set(Fixtures.Storage.sampleProfile, key: "profile", ttl: nil)
    let loaded: Fixtures.Storage.Profile = try storage.value(key: "profile", as: Fixtures.Storage.Profile.self)
    XCTAssertEqual(loaded, Fixtures.Storage.sampleProfile)
  }

  func testValueThrowsNotFoundForMissingKey() {
    XCTAssertThrowsError(try storage.value(key: "missing", as: String.self)) { error in
      guard let storageError = error as? FKStorageError, case .notFound = storageError else {
        XCTFail("Expected FKStorageError.notFound, got \(error)")
        return
      }
    }
  }

  func testExpiredEntryIsTreatedAsMissing() throws {
    try storage.set("temporary", key: "ttl-key", ttl: -1)

    XCTAssertFalse(storage.exists(key: "ttl-key"))
    XCTAssertThrowsError(try storage.value(key: "ttl-key", as: String.self)) { error in
      guard let storageError = error as? FKStorageError, case .notFound = storageError else {
        XCTFail("Expected FKStorageError.notFound, got \(error)")
        return
      }
    }
  }

  func testRemoveDeletesEntry() throws {
    try storage.set(true, key: "flag", ttl: nil)
    XCTAssertTrue(storage.exists(key: "flag"))

    try storage.remove(key: "flag")
    XCTAssertFalse(storage.exists(key: "flag"))
  }

  func testAllKeysReturnsSortedNonExpiredKeys() throws {
    try storage.set(1, key: "b", ttl: nil)
    try storage.set(2, key: "a", ttl: nil)
    try storage.set(3, key: "expired", ttl: -1)

    XCTAssertEqual(try storage.allKeys(), ["a", "b"])
  }

  func testRemoveAllClearsStore() throws {
    try storage.set("x", key: "one", ttl: nil)
    try storage.set("y", key: "two", ttl: nil)

    try storage.removeAll()
    XCTAssertEqual(try storage.allKeys(), [])
  }

  func testStorageKeyFullKeyIsUsedWithMemoryStorage() throws {
    let key = FKStorageStringKey(namespace: Fixtures.Storage.namespace, rawValue: "profile")
    try storage.set(Fixtures.Storage.sampleProfile, key: key.fullKey, ttl: nil)

    let loaded: Fixtures.Storage.Profile = try storage.value(key: key.fullKey, as: Fixtures.Storage.Profile.self)
    XCTAssertEqual(loaded, Fixtures.Storage.sampleProfile)
  }

  func testDecodingWrongTypeThrowsDecodingFailed() throws {
    try storage.set(Fixtures.Storage.sampleProfile, key: "profile", ttl: nil)

    XCTAssertThrowsError(try storage.value(key: "profile", as: String.self)) { error in
      guard let storageError = error as? FKStorageError, case .decodingFailed = storageError else {
        XCTFail("Expected FKStorageError.decodingFailed, got \(error)")
        return
      }
    }
  }
}
