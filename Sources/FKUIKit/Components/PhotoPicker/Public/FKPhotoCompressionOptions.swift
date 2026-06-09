import Foundation

/// Output encoding format for processed still images.
public enum FKPhotoOutputFormat: Sendable, Equatable {
  case jpeg
  case heic
  case png
  case matchSource
}

/// Image resize, encoding, and EXIF options applied after picking.
public struct FKPhotoCompressionOptions: Sendable, Equatable {
  /// Maximum width or height in pixels; `nil` keeps the decoded size.
  public var maxPixelDimension: CGFloat?
  /// JPEG/HEIC quality in `0...1` (default `0.85`).
  public var jpegQuality: CGFloat
  /// Encoded output format.
  public var outputFormat: FKPhotoOutputFormat
  /// Removes GPS location tags before export (default `true`).
  public var stripLocationEXIF: Bool
  /// Removes all EXIF metadata when `true`.
  public var stripAllEXIF: Bool
  /// When `true`, preserves alpha using PNG when needed.
  public var preserveAlpha: Bool

  public init(
    maxPixelDimension: CGFloat? = nil,
    jpegQuality: CGFloat = 0.85,
    outputFormat: FKPhotoOutputFormat = .jpeg,
    stripLocationEXIF: Bool = true,
    stripAllEXIF: Bool = false,
    preserveAlpha: Bool = false
  ) {
    self.maxPixelDimension = maxPixelDimension
    self.jpegQuality = min(max(jpegQuality, 0), 1)
    self.outputFormat = outputFormat
    self.stripLocationEXIF = stripLocationEXIF
    self.stripAllEXIF = stripAllEXIF
    self.preserveAlpha = preserveAlpha
  }
}
