@testable import FKUIKit
import XCTest

@MainActor
final class FKPhotoPickerInputExtractorTests: XCTestCase {
  func testItemFromUIImagePickerInfoUsesEditedImageWhenPresent() throws {
    let image = makeTestImage()
    let item = try FKPhotoPickerInputExtractor.item(from: [
      .editedImage: image,
      .originalImage: UIImage(),
    ])

    XCTAssertEqual(item.mediaType, .image)
    if case let .imageData(data) = item.payload {
      XCTAssertFalse(data.isEmpty)
    } else {
      XCTFail("Expected image payload")
    }
  }

  func testItemFromUIImagePickerInfoUsesOriginalImageWhenEditedMissing() throws {
    let image = makeTestImage()
    let item = try FKPhotoPickerInputExtractor.item(from: [
      .originalImage: image,
    ])

    XCTAssertEqual(item.mediaType, .image)
  }

  func testItemFromUIImagePickerInfoMapsVideoMediaURL() throws {
    let videoURL = FileManager.default.temporaryDirectory.appendingPathComponent("picker-video.mp4")
    try Data([0x00, 0x01]).write(to: videoURL)

    let item = try FKPhotoPickerInputExtractor.item(from: [
      .mediaURL: videoURL,
    ])

    XCTAssertEqual(item.mediaType, .video)
    if case let .videoFileURL(url) = item.payload {
      XCTAssertEqual(url, videoURL)
    } else {
      XCTFail("Expected video payload")
    }
  }

  func testItemFromUIImagePickerInfoThrowsWhenImageEncodingUnavailable() {
    XCTAssertThrowsError(
      try FKPhotoPickerInputExtractor.item(from: [:])
    ) { error in
      XCTAssertEqual(error as? FKPhotoPickerError, .unsupportedMediaType)
    }
  }

  func testItemFromUIImagePickerInfoPrefersMediaURLOverImageFields() throws {
    let videoURL = FileManager.default.temporaryDirectory.appendingPathComponent("picker-priority.mp4")
    try Data([0x00]).write(to: videoURL)

    let item = try FKPhotoPickerInputExtractor.item(from: [
      .mediaURL: videoURL,
      .originalImage: makeTestImage(),
    ])

    XCTAssertEqual(item.mediaType, .video)
  }

  private func makeTestImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
    return renderer.image { context in
      UIColor.red.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    }
  }
}
