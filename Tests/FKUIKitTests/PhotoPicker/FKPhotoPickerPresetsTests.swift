import FKUIKit
import XCTest

final class FKPhotoPickerPresetsTests: XCTestCase {
  func testAvatarPresetUsesSingleSelectionAndStripsLocationEXIF() {
    let configuration = FKPhotoPickerPresets.avatar()

    XCTAssertEqual(configuration.selection.effectiveLimit, 1)
    XCTAssertEqual(configuration.compression.maxPixelDimension, 1024)
    XCTAssertTrue(configuration.compression.stripLocationEXIF)
    XCTAssertTrue(configuration.camera.allowsEditing)
  }

  func testChatAttachmentsUsesProvidedMaxSelection() {
    let configuration = FKPhotoPickerPresets.chatAttachments(max: 6)

    XCTAssertEqual(configuration.selection.effectiveLimit, 6)
    XCTAssertEqual(configuration.compression.maxPixelDimension, 2048)
  }

  func testHighQualitySinglePreservesSourceFormatAndEXIF() {
    let configuration = FKPhotoPickerPresets.highQualitySingle()

    XCTAssertNil(configuration.compression.maxPixelDimension)
    XCTAssertEqual(configuration.compression.outputFormat, .matchSource)
    XCTAssertFalse(configuration.compression.stripLocationEXIF)
  }
}
