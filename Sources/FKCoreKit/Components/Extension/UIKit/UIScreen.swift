#if canImport(UIKit)
import CoreGraphics
import UIKit

public extension UIScreen {
  /// One logical point expressed in pixels for this screen (`1 / scale`).
  var fk_onePixelInPoints: CGFloat {
    1.0 / scale
  }

  /// Native pixel dimensions of the screen bounds.
  var fk_nativePixelBounds: CGRect {
    nativeBounds
  }

  /// Converts points to pixels for this screen.
  func fk_pointsToPixels(_ points: CGFloat) -> CGFloat {
    points * scale
  }

  /// Converts pixels to points for this screen.
  func fk_pixelsToPoints(_ pixels: CGFloat) -> CGFloat {
    scale == 0 ? pixels : pixels / scale
  }
}

#endif
