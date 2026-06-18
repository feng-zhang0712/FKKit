import UIKit

/// @MainActor-only presentation context for hero transitions; not stored in sendable configuration.
@MainActor
public struct FKMediaGalleryTransitionSource {
  /// Source thumbnail view used for hero frame capture.
  public weak var thumbnailView: UIView?
  /// Fallback frame in window coordinates when ``thumbnailView`` is unavailable.
  public var thumbnailFrameInWindow: CGRect?
  public var cornerRadius: CGFloat
  public var placeholderImage: UIImage?
  /// Index in `items` matching the tapped thumbnail; defaults to `startIndex` when `nil`.
  public var itemIndex: Int?

  public init(
    thumbnailView: UIView? = nil,
    thumbnailFrameInWindow: CGRect? = nil,
    cornerRadius: CGFloat = 0,
    placeholderImage: UIImage? = nil,
    itemIndex: Int? = nil
  ) {
    self.thumbnailView = thumbnailView
    self.thumbnailFrameInWindow = thumbnailFrameInWindow
    self.cornerRadius = cornerRadius
    self.placeholderImage = placeholderImage
    self.itemIndex = itemIndex
  }

  /// Resolves the thumbnail frame in window space.
  public func resolvedFrameInWindow() -> CGRect? {
    if let thumbnailView, let window = thumbnailView.window {
      return thumbnailView.convert(thumbnailView.bounds, to: window)
    }
    return thumbnailFrameInWindow
  }
}
