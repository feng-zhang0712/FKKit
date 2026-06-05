import Foundation

#if canImport(UIKit)
  import UIKit
#endif

/// Request to load a remote or local image resource.
public struct FKImageLoadRequest: Sendable, Equatable {
  /// Image URL.
  public var url: URL
  /// Target width in points when the loader supports downsampling.
  public var targetWidth: Double?
  /// Target height in points when the loader supports downsampling.
  public var targetHeight: Double?
  /// Optional cache key override.
  public var cacheKey: String?

  /// Creates an image load request.
  public init(
    url: URL,
    targetWidth: Double? = nil,
    targetHeight: Double? = nil,
    cacheKey: String? = nil
  ) {
    self.url = url
    self.targetWidth = targetWidth
    self.targetHeight = targetHeight
    self.cacheKey = cacheKey
  }

  #if canImport(UIKit)
    /// Creates a request with a `CGSize` target (UIKit targets only).
    public init(url: URL, targetSize: CGSize?, cacheKey: String? = nil) {
      self.url = url
      self.targetWidth = targetSize.map { Double($0.width) }
      self.targetHeight = targetSize.map { Double($0.height) }
      self.cacheKey = cacheKey
    }
  #endif
}

#if canImport(UIKit)

  /// Loads images for UI components without binding to SDWebImage, Kingfisher, etc.
  @MainActor
  public protocol FKImageLoading: AnyObject, Sendable {
    /// Loads an image asynchronously.
    ///
    /// - Parameter request: Load parameters.
    /// - Returns: Decoded image.
    /// - Throws: Network or decoding failures.
    func loadImage(for request: FKImageLoadRequest) async throws -> UIImage

    /// Cancels an in-flight load when supported.
    func cancelLoad(for request: FKImageLoadRequest)
  }

  /// Optional in-memory/disk cache boundary paired with ``FKImageLoading``.
  @MainActor
  public protocol FKImageCaching: AnyObject, Sendable {
    /// Returns a cached image when available.
    func cachedImage(forKey key: String) -> UIImage?

    /// Stores an image.
    func store(_ image: UIImage, forKey key: String)

    /// Evicts a single entry.
    func removeImage(forKey key: String)

    /// Clears all cached images.
    func removeAllImages()
  }

#endif
