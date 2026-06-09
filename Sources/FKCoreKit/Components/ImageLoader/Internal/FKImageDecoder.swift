#if canImport(UIKit)
  import CoreGraphics
  import ImageIO
  import UIKit

  /// Decodes image bytes off the main thread with optional downsampling.
  enum FKImageDecoder {
    static func decode(
      data: Data,
      targetWidth: Double?,
      targetHeight: Double?,
      scale: CGFloat
    ) throws -> UIImage {
      guard !data.isEmpty else {
        throw FKImageLoaderError.corruptData
      }

      let sourceOptions: [CFString: Any] = [
        kCGImageSourceShouldCache: false,
      ]
      guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
        throw FKImageLoaderError.corruptData
      }

      guard CGImageSourceGetCount(source) > 0 else {
        throw FKImageLoaderError.corruptData
      }

      if let type = CGImageSourceGetType(source) as String? {
        let lower = type.lowercased()
        let allowed = ["jpeg", "jpg", "png", "heic", "heif", "gif"]
        guard allowed.contains(where: { lower.contains($0) }) else {
          throw FKImageLoaderError.unsupportedFormat(type)
        }
      }

      let maxPixelSize = maxPixelSize(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        source: source,
        scale: scale
      )

      if let maxPixelSize {
        let thumbnailOptions: [CFString: Any] = [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceShouldCacheImmediately: true,
          kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) {
          return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
        }
      }

      guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, sourceOptions as CFDictionary) else {
        throw FKImageLoaderError.decodeFailed
      }

      var image = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
      if let targetSize = resolvedTargetSize(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        imageSize: image.size
      ), targetSize != image.size {
        image = image.fk_resized(to: targetSize) ?? image
      }
      return image
    }

    static func encodedData(from image: UIImage) -> Data? {
      image.pngData() ?? image.jpegData(compressionQuality: 0.9)
    }

    private static func maxPixelSize(
      targetWidth: Double?,
      targetHeight: Double?,
      source: CGImageSource,
      scale: CGFloat
    ) -> Int? {
      switch (targetWidth, targetHeight) {
      case let (width?, height?):
        return Int(max(width, height) * Double(scale))
      case let (width?, nil):
        let sourcePixelHeight = pixelHeight(from: source)
        if sourcePixelHeight > 0 {
          let aspect = sourcePixelHeight / pixelWidth(from: source)
          return Int(max(width * aspect, width) * Double(scale))
        }
        return Int(width * Double(scale))
      case let (nil, height?):
        let pixelWidth = pixelWidth(from: source)
        let sourcePixelHeight = pixelHeight(from: source)
        if sourcePixelHeight > 0 {
          let aspect = pixelWidth / sourcePixelHeight
          return Int(max(height * aspect, height) * Double(scale))
        }
        return Int(height * Double(scale))
      case (nil, nil):
        return nil
      }
    }

    private static func resolvedTargetSize(
      targetWidth: Double?,
      targetHeight: Double?,
      imageSize: CGSize
    ) -> CGSize? {
      switch (targetWidth, targetHeight) {
      case let (width?, height?):
        return CGSize(width: width, height: height)
      case let (width?, nil):
        guard imageSize.width > 0 else { return nil }
        let height = imageSize.height / imageSize.width * width
        return CGSize(width: width, height: height)
      case let (nil, height?):
        guard imageSize.height > 0 else { return nil }
        let width = imageSize.width / imageSize.height * height
        return CGSize(width: width, height: height)
      case (nil, nil):
        return nil
      }
    }

    private static func pixelWidth(from source: CGImageSource) -> Double {
      guard
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
        let width = properties[kCGImagePropertyPixelWidth] as? NSNumber
      else { return 1 }
      return width.doubleValue
    }

    private static func pixelHeight(from source: CGImageSource) -> Double {
      guard
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
        let height = properties[kCGImagePropertyPixelHeight] as? NSNumber
      else { return 1 }
      return height.doubleValue
    }
  }
#endif
