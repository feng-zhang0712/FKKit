#if canImport(UIKit)
import CoreImage
import UIKit

/// Generates QR code images using `CIQRCodeGenerator`.
public enum FKQRCodeGenerator {
  /// Maximum UTF-8 byte length for version-40 QR at correction level L (binary mode).
  public static let maxContentBytes = 2953

  private static let ciContext = CIContext(options: nil)

  /// Creates a scaled, colored QR `UIImage`.
  ///
  /// - Parameters:
  ///   - string: UTF-8 payload.
  ///   - options: Size, colors, correction level, and optional center logo.
  /// - Returns: A bitmap suitable for `UIImageView`.
  public static func makeImage(
    from string: String,
    options: FKQRCodeGenerationOptions = .default
  ) throws -> UIImage {
    let ciImage = try makeCIImage(from: string, options: options)
    guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
      throw FKQRCodeError.imageConversionFailed
    }

    var image = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    if let logo = options.logo {
      image = try embedLogo(logo, in: image, qrSize: options.size)
    }
    return image
  }

  /// Creates a scaled, colored QR `CIImage` without logo compositing.
  ///
  /// - Parameters:
  ///   - string: UTF-8 payload.
  ///   - options: Size, colors, and correction level.
  /// - Returns: A Core Image representation scaled with nearest-neighbor transforms.
  public static func makeCIImage(
    from string: String,
    options: FKQRCodeGenerationOptions = .default
  ) throws -> CIImage {
    let normalized = try normalizedContent(from: string)
    let correctionLevel = options.logo == nil ? options.correctionLevel : .H

    guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
      throw FKQRCodeError.filterFailed
    }
    filter.setValue(normalized, forKey: "inputMessage")
    filter.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")

    guard var output = filter.outputImage else {
      throw FKQRCodeError.filterFailed
    }

    output = applyColors(
      to: output,
      foreground: options.foregroundColor,
      background: options.backgroundColor
    )

    let targetSize = options.size
    guard targetSize.width > 0, targetSize.height > 0 else {
      throw FKQRCodeError.imageConversionFailed
    }

    let scaleX = targetSize.width / output.extent.width
    let scaleY = targetSize.height / output.extent.height
    return output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
  }

  // MARK: - Private

  private static func normalizedContent(from string: String) throws -> Data {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw FKQRCodeError.emptyContent
    }
    guard let data = trimmed.data(using: .utf8) else {
      throw FKQRCodeError.filterFailed
    }
    guard data.count <= maxContentBytes else {
      throw FKQRCodeError.contentTooLong(maxBytes: maxContentBytes)
    }
    return data
  }

  private static func applyColors(to image: CIImage, foreground: UIColor, background: UIColor) -> CIImage {
    guard let filter = CIFilter(name: "CIFalseColor") else { return image }
    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(CIColor(color: foreground), forKey: "inputColor0")
    filter.setValue(CIColor(color: background), forKey: "inputColor1")
    return filter.outputImage ?? image
  }

  private static func embedLogo(
    _ embedding: FKQRCodeLogoEmbedding,
    in qrImage: UIImage,
    qrSize: CGSize
  ) throws -> UIImage {
    let side = min(qrSize.width, qrSize.height)
    let maxRelative = min(max(embedding.maxRelativeSize, 0), 0.22)
    let logoSide = side * maxRelative
    guard logoSide > 0 else { return qrImage }

    let format = UIGraphicsImageRendererFormat.default()
    format.scale = qrImage.scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: qrSize, format: format)
    return renderer.image { _ in
      qrImage.draw(in: CGRect(origin: .zero, size: qrSize))

      let logoRect = CGRect(
        x: (qrSize.width - logoSide) / 2,
        y: (qrSize.height - logoSide) / 2,
        width: logoSide,
        height: logoSide
      )
      let padding: CGFloat = 4
      let backgroundRect = logoRect.insetBy(dx: -padding, dy: -padding)
      UIColor.systemBackground.setFill()
      UIBezierPath(
        roundedRect: backgroundRect,
        cornerRadius: embedding.cornerRadius + padding
      ).fill()

      if embedding.cornerRadius > 0 {
        let path = UIBezierPath(roundedRect: logoRect, cornerRadius: embedding.cornerRadius)
        path.addClip()
      }
      embedding.image.draw(in: logoRect)
    }
  }
}
#endif
