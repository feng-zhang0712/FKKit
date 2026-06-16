import FKCoreKit
import XCTest

final class FKFileMimeResolverTests: XCTestCase {
  func testMimeTypeForKnownPNGExtension() {
    XCTAssertEqual(FKFileMimeResolver.mimeType(forFileExtension: "png"), "image/png")
  }

  func testMimeTypeForKnownJSONExtension() {
    XCTAssertEqual(FKFileMimeResolver.mimeType(forFileExtension: "json"), "application/json")
  }

  func testMimeTypeForUnknownExtensionFallsBackToOctetStream() {
    XCTAssertEqual(FKFileMimeResolver.mimeType(forFileExtension: "fkkit-unknown-ext"), "application/octet-stream")
  }

  func testMimeTypeForFileURLUsesPathExtension() {
    let url = URL(fileURLWithPath: "/tmp/sample.pdf")
    XCTAssertEqual(FKFileMimeResolver.mimeType(forFileURL: url), "application/pdf")
  }
}
