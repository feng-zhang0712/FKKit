import FKCoreKit
import XCTest

final class FileManagerExtensionTests: XCTestCase {
  func testStandardDirectoryURLsExist() {
    var isDirectory: ObjCBool = false

    XCTAssertTrue(
      FileManager.default.fileExists(atPath: FileManager.fk_documentsDirectory.path, isDirectory: &isDirectory)
    )
    XCTAssertTrue(isDirectory.boolValue)

    isDirectory = false
    XCTAssertTrue(
      FileManager.default.fileExists(atPath: FileManager.fk_temporaryDirectory.path, isDirectory: &isDirectory)
    )
    XCTAssertTrue(isDirectory.boolValue)
  }

  func testFileSizeReturnsByteCountForRegularFile() throws {
    let url = FileManager.fk_temporaryDirectory.appendingPathComponent("fk-file-size-\(UUID().uuidString).txt")
    defer { try? FileManager.default.removeItem(at: url) }

    try Data("hello".utf8).write(to: url)
    XCTAssertEqual(FileManager.default.fk_fileSize(at: url), 5)
  }
}
