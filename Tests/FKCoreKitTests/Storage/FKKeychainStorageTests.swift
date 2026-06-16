import FKCoreKit
import XCTest

final class FKKeychainStorageTests: XCTestCase {
  private var storage: FKKeychainStorage!
  private var serviceName = ""

  override func setUpWithError() throws {
    try super.setUpWithError()
    serviceName = "com.fkkit.tests.keychain.\(UUID().uuidString)"
    storage = FKKeychainStorage(service: serviceName)

    do {
      try storage.set(true, key: "__probe__", ttl: nil)
      try storage.remove(key: "__probe__")
    } catch let error as FKStorageError {
      if case let .keychainFailed(status) = error {
        throw XCTSkip("Keychain unavailable in test host (status: \(status))")
      }
      throw error
    }
  }

  override func tearDown() {
    try? storage.remove(key: "profile")
    try? storage.remove(key: "ttl-key")
    try? storage.remove(key: "flag")
    storage = nil
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
}
