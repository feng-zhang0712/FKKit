import UIKit

/// Downsample target sizes for gallery image decode and prefetch.
enum FKMediaGalleryImageLoadingMath {
  /// Radius of pages around `currentIndex` that may retain decoded bitmaps.
  static func retentionRadius(for maxRetainedImagePages: Int) -> Int {
    max(0, (max(1, maxRetainedImagePages) - 1) / 2)
  }

  /// Pixel dimensions for decode requests.
  ///
  /// - Parameters:
  ///   - bounds: Page layout bounds in points.
  ///   - screenScale: Screen scale factor.
  ///   - maximumZoomScale: Configured pinch/double-tap ceiling.
  ///   - isCurrentPage: When `true`, sizes for full zoom headroom; neighbors use screen fit only.
  static func decodeTargetSize(
    bounds: CGSize,
    screenScale: CGFloat,
    maximumZoomScale: CGFloat,
    isCurrentPage: Bool
  ) -> CGSize {
    guard bounds.width > 0, bounds.height > 0 else { return .zero }
    let zoomFactor = isCurrentPage ? max(1, maximumZoomScale) : 1
    return CGSize(
      width: bounds.width * screenScale * zoomFactor,
      height: bounds.height * screenScale * zoomFactor
    )
  }

  static func screenScale(for view: UIView) -> CGFloat {
    view.window?.screen.scale ?? UIScreen.main.scale
  }
}
