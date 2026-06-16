import FKCoreKit
import UIKit
import XCTest

@MainActor
final class FKQRCodeGenerationOptionsTests: XCTestCase {
  func testDefaultUses256SquareAndMediumCorrection() {
    let options = FKQRCodeGenerationOptions.default

    XCTAssertEqual(options.size.width, 256, accuracy: 0.001)
    XCTAssertEqual(options.size.height, 256, accuracy: 0.001)
    XCTAssertEqual(options.correctionLevel, .M)
    XCTAssertNil(options.logo)
  }

  func testMakeImageProducesBitmapForSimplePayload() throws {
    let image = try FKQRCodeGenerator.makeImage(from: "https://example.com", options: .default)
    XCTAssertGreaterThan(image.size.width, 0)
    XCTAssertGreaterThan(image.size.height, 0)
  }
}
