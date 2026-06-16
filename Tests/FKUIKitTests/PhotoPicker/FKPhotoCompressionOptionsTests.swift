import FKUIKit
import XCTest

final class FKPhotoCompressionOptionsTests: XCTestCase {
  func testDefaultOptionsUseJPEGWithLocationStripping() {
    let options = FKPhotoCompressionOptions()

    XCTAssertEqual(options.jpegQuality, 0.85, accuracy: 0.001)
    XCTAssertEqual(options.outputFormat, .jpeg)
    XCTAssertTrue(options.stripLocationEXIF)
    XCTAssertFalse(options.stripAllEXIF)
    XCTAssertFalse(options.preserveAlpha)
  }

  func testInitClampsJPEGQualityIntoZeroThroughOne() {
    let options = FKPhotoCompressionOptions(jpegQuality: 2)
    XCTAssertEqual(options.jpegQuality, 1, accuracy: 0.001)

    let lowQuality = FKPhotoCompressionOptions(jpegQuality: -1)
    XCTAssertEqual(lowQuality.jpegQuality, 0, accuracy: 0.001)
  }
}
