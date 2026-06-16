import FKCoreKit
import XCTest

@MainActor
final class FKFileManagerStorageTests: XCTestCase {
  private var manager: FKFileManager!

  override func setUp() {
    super.setUp()
    manager = FKFileManager()
  }

  override func tearDown() {
    manager = nil
    super.tearDown()
  }

  func testWriteAndReadTextRoundTrip() async throws {
    let url = manager.directoryURL(.temporary)
      .appendingPathComponent("fkkit-file-test-\(UUID().uuidString).txt")

    try await manager.writeContent(.text("FKKit file round-trip"), to: url)
    let text = try await manager.readText(from: url)
    XCTAssertEqual(text, "FKKit file round-trip")

    try await manager.removeItem(at: url)
  }

  func testExistsReturnsFalseForMissingFile() {
    let url = manager.directoryURL(.temporary)
      .appendingPathComponent("fkkit-missing-\(UUID().uuidString).txt")
    XCTAssertFalse(manager.exists(at: url))
  }

  func testWriteModelAndReadModelRoundTrip() async throws {
    struct Note: Codable, Sendable, Equatable {
      let title: String
    }

    let url = manager.directoryURL(.temporary)
      .appendingPathComponent("fkkit-model-\(UUID().uuidString).json")

    try await manager.writeModel(Note(title: "Test"), to: url)
    let loaded: Note = try await manager.readModel(Note.self, from: url)
    XCTAssertEqual(loaded, Note(title: "Test"))

    try await manager.removeItem(at: url)
  }
}
