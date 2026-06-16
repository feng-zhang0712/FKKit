import FKCoreKit
import XCTest

final class FKZipOptionsTests: XCTestCase {
  func testZipOptionsDefaultIncludesRootDirectoryAndDeflate() {
    let options = FKZipOptions()
    XCTAssertTrue(options.includesRootDirectoryName)
    XCTAssertEqual(options.compressionMethod, .deflate)
  }

  func testUnzipOptionsDefaultReplacesExistingEntries() {
    let options = FKUnzipOptions()
    XCTAssertEqual(options.overwritePolicy, .replaceExisting)
  }
}
