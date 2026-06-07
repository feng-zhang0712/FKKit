#if canImport(UIKit)
import CoreGraphics
import UIKit

public extension UIImage {
  /// Returns a new image scaled to `size` using a high-quality bitmap renderer.
  func fk_resized(to size: CGSize) -> UIImage? {
    guard size.width > 0, size.height > 0 else { return nil }
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { _ in
      draw(in: CGRect(origin: .zero, size: size))
    }
  }

  /// Returns a new image filled with `color` while preserving the alpha mask of the original.
  func fk_tinted(with color: UIColor) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = scale
    format.opaque = false
    let rect = CGRect(origin: .zero, size: size)
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { _ in
      color.setFill()
      UIRectFill(rect)
      draw(in: rect, blendMode: .destinationIn, alpha: 1)
    }
  }

  /// Rounds corners with the given radii; uses the image's current scale.
  func fk_roundingCorners(_ radius: CGFloat, corners: UIRectCorner = .allCorners) -> UIImage {
    let rect = CGRect(origin: .zero, size: size)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { _ in
      let path = UIBezierPath(
        roundedRect: rect,
        byRoundingCorners: corners,
        cornerRadii: CGSize(width: radius, height: radius)
      )
      path.addClip()
      draw(in: rect)
    }
  }

  /// Compresses the image to at most `maxBytes` using JPEG quality reduction.
  func fk_jpegData(maxBytes: Int, minQuality: CGFloat = 0.2) -> Data? {
    guard maxBytes > 0 else { return nil }
    var quality: CGFloat = 1.0
    guard var data = jpegData(compressionQuality: quality) else { return nil }
    if data.count <= maxBytes { return data }
    while data.count > maxBytes, quality > minQuality {
      quality -= 0.1
      guard let next = jpegData(compressionQuality: quality) else { break }
      data = next
    }
    return data.count <= maxBytes ? data : nil
  }

  /// Crops the image to `rect` in point coordinates.
  func fk_cropped(to rect: CGRect) -> UIImage? {
    let scaled = CGRect(
      x: rect.origin.x * scale,
      y: rect.origin.y * scale,
      width: rect.width * scale,
      height: rect.height * scale
    )
    guard let cg = cgImage?.cropping(to: scaled) else { return nil }
    return UIImage(cgImage: cg, scale: scale, orientation: imageOrientation)
  }

  /// Returns a solid-color image.
  static func fk_solidColor(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      color.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
  }

  /// JPEG Base64 representation.
  func fk_jpegBase64String(compressionQuality: CGFloat = 1) -> String? {
    jpegData(compressionQuality: compressionQuality)?.base64EncodedString()
  }

  /// Creates an image from a Base64-encoded JPEG payload.
  static func fk_image(fromBase64JPEG string: String) -> UIImage? {
    guard let data = Data(base64Encoded: string) else { return nil }
    return UIImage(data: data)
  }
}

#endif
