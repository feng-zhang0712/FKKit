import FKCoreKit
import UIKit
import XCTest

final class FKQRCodeGeneratorTests: XCTestCase {
  func testMakeCIImageProducesNonEmptyExtent() throws {
    let image = try FKQRCodeGenerator.makeCIImage(from: "https://fkkit.test", options: .default)
    XCTAssertGreaterThan(image.extent.width, 0)
    XCTAssertGreaterThan(image.extent.height, 0)
  }

  func testMakeImageReturnsBitmap() throws {
    let image = try FKQRCodeGenerator.makeImage(from: "FKKit", options: .default)
    XCTAssertGreaterThan(image.size.width, 0)
    XCTAssertGreaterThan(image.size.height, 0)
  }

  func testEmptyContentThrowsEmptyContentError() {
    XCTAssertThrowsError(try FKQRCodeGenerator.makeCIImage(from: "   ")) { error in
      XCTAssertEqual(error as? FKQRCodeError, .emptyContent)
    }
  }

  func testOversizedContentThrowsContentTooLong() {
    let oversized = String(repeating: "a", count: FKQRCodeGenerator.maxContentBytes + 1)
    XCTAssertThrowsError(try FKQRCodeGenerator.makeCIImage(from: oversized)) { error in
      guard case let .contentTooLong(maxBytes) = error as? FKQRCodeError else {
        XCTFail("Expected contentTooLong, got \(error)")
        return
      }
      XCTAssertEqual(maxBytes, FKQRCodeGenerator.maxContentBytes)
    }
  }
}
