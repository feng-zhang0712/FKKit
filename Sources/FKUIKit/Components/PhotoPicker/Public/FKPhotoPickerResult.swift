import UIKit

/// A single asset returned from a pick session.
///
/// Contains UIKit types and is delivered on the main actor. Copy ``data`` or ``fileURL`` to a
/// background task before starting network upload work.
public struct FKPhotoPickerResult: @unchecked Sendable {
  /// Stable identifier for this result (`UUID` string).
  public var id: String
  /// Resolved media category.
  public var mediaType: FKPhotoPickerMediaType
  /// In-memory image when delivery includes image (full image or video thumbnail).
  public var image: UIImage?
  /// Compressed payload when delivery includes data.
  public var data: Data?
  /// Temporary file URL for upload pipelines.
  public var fileURL: URL?
  /// Optional small preview image.
  public var thumbnail: UIImage?
  /// Pixel dimensions of the primary still image.
  public var pixelSize: CGSize
  /// Byte size of ``data`` or on-disk file when known.
  public var byteCount: Int?
  /// Uniform type identifier string when known.
  public var uniformTypeIdentifier: String?
  /// PHPicker asset identifier when available.
  public var assetIdentifier: String?
  /// EXIF dictionary when retained; `nil` when stripped.
  public var exifProperties: [String: Any]?

  public init(
    id: String = UUID().uuidString,
    mediaType: FKPhotoPickerMediaType,
    image: UIImage? = nil,
    data: Data? = nil,
    fileURL: URL? = nil,
    thumbnail: UIImage? = nil,
    pixelSize: CGSize = .zero,
    byteCount: Int? = nil,
    uniformTypeIdentifier: String? = nil,
    assetIdentifier: String? = nil,
    exifProperties: [String: Any]? = nil
  ) {
    self.id = id
    self.mediaType = mediaType
    self.image = image
    self.data = data
    self.fileURL = fileURL
    self.thumbnail = thumbnail
    self.pixelSize = pixelSize
    self.byteCount = byteCount
    self.uniformTypeIdentifier = uniformTypeIdentifier
    self.assetIdentifier = assetIdentifier
    self.exifProperties = exifProperties
  }
}

extension FKPhotoPickerResult: Equatable {
  public static func == (lhs: FKPhotoPickerResult, rhs: FKPhotoPickerResult) -> Bool {
    lhs.id == rhs.id
      && lhs.mediaType == rhs.mediaType
      && lhs.pixelSize == rhs.pixelSize
      && lhs.byteCount == rhs.byteCount
      && lhs.uniformTypeIdentifier == rhs.uniformTypeIdentifier
      && lhs.assetIdentifier == rhs.assetIdentifier
      && lhs.fileURL == rhs.fileURL
      && lhs.data == rhs.data
  }
}
