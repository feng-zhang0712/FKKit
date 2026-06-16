import FKCoreKit
import XCTest

final class FKFileStorageTests: XCTestCase {
  private var storage: FKFileStorage!
  private var directoryName = ""

  override func setUp() {
    super.setUp()
    directoryName = "FKFileStorageTests-\(UUID().uuidString)"
    storage = try? FKFileStorage(directoryName: directoryName)
  }

  override func tearDown() {
    storage = nil
    if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      try? FileManager.default.removeItem(at: support.appendingPathComponent(directoryName, isDirectory: true))
    }
    super.tearDown()
  }

  func testSetAndValueRoundTrip() throws {
    try storage.set(Fixtures.Storage.sampleProfile, key: "profile", ttl: nil)
    let loaded: Fixtures.Storage.Profile = try storage.value(key: "profile", as: Fixtures.Storage.Profile.self)
    XCTAssertEqual(loaded, Fixtures.Storage.sampleProfile)
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

  func testAllKeysReturnsIndexedKeys() throws {
    try storage.set(1, key: "b", ttl: nil)
    try storage.set(2, key: "a", ttl: nil)

    XCTAssertEqual(Set(try storage.allKeys()), Set(["a", "b"]))
  }

  func testPurgeExpiredRemovesStaleEntries() throws {
    try storage.set(1, key: "live", ttl: nil)
    try storage.set(2, key: "expired", ttl: -1)

    try storage.purgeExpired()

    XCTAssertEqual(try storage.allKeys(), ["live"])
    XCTAssertFalse(storage.exists(key: "expired"))
  }
}
