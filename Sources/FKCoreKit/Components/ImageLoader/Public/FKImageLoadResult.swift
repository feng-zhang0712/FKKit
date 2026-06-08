#if canImport(UIKit)
  import UIKit

  /// Result of a detailed ``FKImageLoader/loadImageResult(for:options:)`` call.
  public struct FKImageLoadResult: Sendable {
    /// Decoded image ready for display.
    public let image: UIImage
    /// Original encoded bytes when ``FKImageLoadOptions/returnsSourceData`` is `true`.
    public let sourceData: Data?
    /// `true` when the image was returned from memory or disk without network I/O.
    public let wasCached: Bool

    /// Creates a load result.
    public init(image: UIImage, sourceData: Data?, wasCached: Bool) {
      self.image = image
      self.sourceData = sourceData
      self.wasCached = wasCached
    }
  }
#endif
