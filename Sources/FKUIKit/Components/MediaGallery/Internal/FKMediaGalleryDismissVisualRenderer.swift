import AVFoundation
import UIKit

@MainActor
enum FKMediaGalleryDismissVisualRenderer {
  /// Renders `view` into a bitmap for aspect-fit interactive dismiss.
  static func image(from view: UIView) -> UIImage? {
    guard view.bounds.width > 0, view.bounds.height > 0 else { return nil }
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = UIScreen.main.scale
    let renderer = UIGraphicsImageRenderer(bounds: view.bounds, format: format)
    return renderer.image { _ in
      view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    }
  }

  /// Builds unified dismiss media for gallery video pages (poster or video frame only).
  static func videoMediaContent(
    playerView: FKVideoPlayerView,
    player: FKVideoPlayer?
  ) -> (image: UIImage, contentSize: CGSize)? {
    guard let image = playerView.dismissMediaBitmap() else { return nil }
    let contentSize = naturalVideoSize(from: player)
      ?? FKMediaGalleryLayoutMath.resolvedImageSize(from: image)
    guard contentSize.width > 0, contentSize.height > 0 else { return nil }
    return (image, contentSize)
  }

  /// Resolves a transition-source bitmap for dismiss fallback.
  static func transitionSourceImage(from source: FKMediaGalleryTransitionSource) -> UIImage? {
    if let image = source.placeholderImage {
      return image
    }
    if let imageView = source.thumbnailView as? FKImageView, let image = imageView.image {
      return image
    }
    if let imageView = source.thumbnailView as? UIImageView, let image = imageView.image {
      return image
    }
    return nil
  }

  /// Resolves aspect-fit content size for hero transitions.
  static func transitionSourceContentSize(
    from source: FKMediaGalleryTransitionSource,
    fallback: CGSize
  ) -> CGSize {
    if let image = transitionSourceImage(from: source) {
      return FKMediaGalleryLayoutMath.resolvedImageSize(from: image)
    }
    if source.thumbnailView?.bounds.width ?? 0 > 0 {
      return source.thumbnailView?.bounds.size ?? fallback
    }
    return fallback
  }

  private static func naturalVideoSize(from player: FKVideoPlayer?) -> CGSize? {
    guard let track = player?.coordinator.avPlayerItem?.asset
      .tracks(withMediaType: .video)
      .first else {
      return nil
    }
    let transformed = track.naturalSize.applying(track.preferredTransform)
    let width = abs(transformed.width)
    let height = abs(transformed.height)
    guard width > 0, height > 0 else { return nil }
    return CGSize(width: width, height: height)
  }
}
