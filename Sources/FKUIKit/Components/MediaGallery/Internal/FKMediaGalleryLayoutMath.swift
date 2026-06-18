import UIKit

enum FKMediaGalleryLayoutMath {
  /// Computes the aspect-fit rect for `contentSize` inside `bounds`.
  static func aspectFitFrame(contentSize: CGSize, in bounds: CGRect) -> CGRect {
    guard contentSize.width > 0, contentSize.height > 0, bounds.width > 0, bounds.height > 0 else {
      return .zero
    }
    let scale = min(bounds.width / contentSize.width, bounds.height / contentSize.height)
    let fitted = CGSize(width: contentSize.width * scale, height: contentSize.height * scale)
    return CGRect(
      x: bounds.midX - fitted.width * 0.5,
      y: bounds.midY - fitted.height * 0.5,
      width: fitted.width,
      height: fitted.height
    )
  }

  static func resolvedImageSize(from image: UIImage?) -> CGSize {
    guard let image else { return .zero }
    let pixelSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    return pixelSize.width > 0 && pixelSize.height > 0 ? pixelSize : image.size
  }

  /// Interpolates between aspect-fit placements of the same `contentSize` inside two containers.
  static func aspectFitFrameInterpolated(
    contentSize: CGSize,
    startContainer: CGRect,
    endContainer: CGRect,
    progress: CGFloat
  ) -> CGRect {
    let start = aspectFitFrame(contentSize: contentSize, in: startContainer)
    let end = aspectFitFrame(contentSize: contentSize, in: endContainer)
    let t = min(max(progress, 0), 1)
    return CGRect(
      x: start.origin.x + (end.origin.x - start.origin.x) * t,
      y: start.origin.y + (end.origin.y - start.origin.y) * t,
      width: start.size.width + (end.size.width - start.size.width) * t,
      height: start.size.height + (end.size.height - start.size.height) * t
    )
  }
}
