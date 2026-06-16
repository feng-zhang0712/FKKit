import FKCoreKit
import XCTest

final class StringHashingExtensionTests: XCTestCase {
  func testMD5AndSHA256ProduceLowercaseHexDigests() {
    let value = "fkkit"

    XCTAssertEqual(value.fk_md5.count, 32)
    XCTAssertEqual(value.fk_sha256.count, 64)
    XCTAssertEqual(value.fk_md5, value.fk_md5.lowercased())
    XCTAssertEqual(value.fk_sha256, value.fk_sha256.lowercased())
  }

  func testHashDigestsAreStableForSameInput() {
    let first = "stable-input".fk_sha256
    let second = "stable-input".fk_sha256

    XCTAssertEqual(first, second)
  }
}
