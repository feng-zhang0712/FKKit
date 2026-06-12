import AVFoundation
import CoreGraphics
import FKCoreKit
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// Background image and video processing for picked assets.
enum FKPhotoProcessingPipeline {
  private static let maxConcurrentTasks = 2

  static func processItems(
    _ items: [FKPhotoPickerProcessingItem],
    configuration: FKPhotoPickerConfiguration,
    tempStore: FKPhotoTempFileStore,
    progressHandler: FKPhotoPickerProgressHandler?
  ) async throws -> [FKPhotoPickerResult] {
    let total = items.count
    guard total > 0 else { return [] }

    var output = [FKPhotoPickerResult?](repeating: nil, count: total)
    var processedCount = 0

    try await withThrowingTaskGroup(of: (Int, FKPhotoPickerResult).self) { group in
      var nextIndex = 0

      func enqueue(_ index: Int) {
        let item = items[index]
        group.addTask {
          let processed = try await processItem(
            item,
            configuration: configuration,
            tempStore: tempStore
          )
          return (index, processed)
        }
      }

      let initial = min(maxConcurrentTasks, total)
      while nextIndex < initial {
        enqueue(nextIndex)
        nextIndex += 1
      }

      while let (index, item) = try await group.next() {
        output[index] = item
        processedCount += 1
        if let progressHandler {
          await MainActor.run {
            progressHandler(processedCount, total)
          }
        }
        if nextIndex < total {
          enqueue(nextIndex)
          nextIndex += 1
        }
      }
    }

    return output.compactMap { $0 }
  }

  private static func processItem(
    _ item: FKPhotoPickerProcessingItem,
    configuration: FKPhotoPickerConfiguration,
    tempStore: FKPhotoTempFileStore
  ) async throws -> FKPhotoPickerResult {
    switch item.payload {
    case let .imageData(data):
      return try await processImageData(
        data,
        assetIdentifier: item.assetIdentifier,
        mediaType: item.mediaType,
        configuration: configuration,
        tempStore: tempStore
      )
    case let .videoFileURL(url):
      return try await processVideoFile(
        at: url,
        assetIdentifier: item.assetIdentifier,
        configuration: configuration,
        tempStore: tempStore,
        alreadyCopied: url.path.contains("/FKPhotoPicker/")
      )
    }
  }

  private static func processImageData(
    _ data: Data,
    assetIdentifier: String?,
    mediaType: FKPhotoPickerMediaType,
    configuration: FKPhotoPickerConfiguration,
    tempStore: FKPhotoTempFileStore
  ) async throws -> FKPhotoPickerResult {
    let scale = await MainActor.run { UIScreen.main.scale }
    let maxDimension = configuration.compression.maxPixelDimension.map(Double.init)

    let image = try FKPhotoPickerImageDecoder.decode(
      data: data,
      targetWidth: maxDimension,
      targetHeight: maxDimension,
      scale: scale
    )

    return try buildImageResult(
      from: image,
      sourceData: data,
      assetIdentifier: assetIdentifier,
      mediaType: mediaType,
      configuration: configuration,
      tempStore: tempStore
    )
  }

  private static func buildImageResult(
    from image: UIImage,
    sourceData: Data,
    assetIdentifier: String?,
    mediaType: FKPhotoPickerMediaType,
    configuration: FKPhotoPickerConfiguration,
    tempStore: FKPhotoTempFileStore
  ) throws -> FKPhotoPickerResult {
    let encoded = try encodeImage(image, sourceData: sourceData, configuration: configuration.compression)
    let stripped = FKPhotoEXIFStripper.stripMetadata(
      from: encoded.data,
      stripLocation: configuration.compression.stripLocationEXIF,
      stripAll: configuration.compression.stripAllEXIF
    ) ?? encoded.data

    var result = FKPhotoPickerResult(
      mediaType: mediaType,
      pixelSize: pixelSize(of: image),
      uniformTypeIdentifier: encoded.uti,
      assetIdentifier: assetIdentifier
    )

    if configuration.delivery.includesImage {
      result.image = image
    }

    if configuration.delivery.includesData {
      result.data = stripped
      result.byteCount = stripped.count
    }

    if configuration.delivery.includesFileURL {
      let url = try write(data: stripped, fileExtension: encoded.fileExtension, tempStore: tempStore)
      result.fileURL = url
      result.byteCount = stripped.count
    } else if result.byteCount == nil {
      result.byteCount = stripped.count
    }

    if !configuration.compression.stripLocationEXIF, !configuration.compression.stripAllEXIF {
      result.exifProperties = FKPhotoEXIFStripper.extractProperties(from: sourceData)
    }

    return result
  }

  private static func processVideoFile(
    at url: URL,
    assetIdentifier: String?,
    configuration: FKPhotoPickerConfiguration,
    tempStore: FKPhotoTempFileStore,
    alreadyCopied: Bool
  ) async throws -> FKPhotoPickerResult {
    let destinationURL: URL
    if alreadyCopied {
      destinationURL = url
      tempStore.register(url)
    } else {
      let data = try Data(contentsOf: url)
      try validateVideoSize(data.count, configuration: configuration)
      destinationURL = try write(
        data: data,
        fileExtension: url.pathExtension.isEmpty ? "mov" : url.pathExtension,
        tempStore: tempStore
      )
    }

    let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
    let byteCount = attributes[.size] as? Int ?? 0
    try validateVideoSize(byteCount, configuration: configuration)

    let thumbnail = try await generateVideoThumbnail(for: destinationURL)
    var result = FKPhotoPickerResult(
      mediaType: .video,
      fileURL: destinationURL,
      thumbnail: thumbnail,
      pixelSize: thumbnail.map(pixelSize) ?? .zero,
      byteCount: byteCount,
      uniformTypeIdentifier: UTType.movie.identifier,
      assetIdentifier: assetIdentifier
    )

    if configuration.delivery.includesImage {
      result.image = thumbnail
    }

    return result
  }

  private static func encodeImage(
    _ image: UIImage,
    sourceData: Data,
    configuration: FKPhotoCompressionOptions
  ) throws -> (data: Data, uti: String, fileExtension: String) {
    let format = resolvedOutputFormat(configuration: configuration, sourceData: sourceData, image: image)

    switch format {
    case .jpeg:
      guard let data = image.jpegData(compressionQuality: configuration.jpegQuality) else {
        throw FKPhotoPickerError.processingFailed(underlyingDescription: "JPEG encoding failed.")
      }
      return (data, UTType.jpeg.identifier, "jpg")
    case .heic:
      if let data = image.heicData(compressionQuality: configuration.jpegQuality) {
        return (data, UTType.heic.identifier, "heic")
      }
      guard let data = image.jpegData(compressionQuality: configuration.jpegQuality) else {
        throw FKPhotoPickerError.processingFailed(underlyingDescription: "HEIC/JPEG encoding failed.")
      }
      return (data, UTType.jpeg.identifier, "jpg")
    case .png:
      guard let data = image.pngData() else {
        throw FKPhotoPickerError.processingFailed(underlyingDescription: "PNG encoding failed.")
      }
      return (data, UTType.png.identifier, "png")
    case .matchSource:
      if
        let source = CGImageSourceCreateWithData(sourceData as CFData, nil),
        let type = CGImageSourceGetType(source) as String?
      {
        if type.contains("heic") || type.contains("heif"),
           let data = image.heicData(compressionQuality: configuration.jpegQuality) {
          return (data, UTType.heic.identifier, "heic")
        }
        if type.contains("png"), configuration.preserveAlpha, let data = image.pngData() {
          return (data, UTType.png.identifier, "png")
        }
      }
      guard let data = image.jpegData(compressionQuality: configuration.jpegQuality) else {
        throw FKPhotoPickerError.processingFailed(underlyingDescription: "JPEG encoding failed.")
      }
      return (data, UTType.jpeg.identifier, "jpg")
    }
  }

  private static func resolvedOutputFormat(
    configuration: FKPhotoCompressionOptions,
    sourceData: Data,
    image: UIImage
  ) -> FKPhotoOutputFormat {
    if configuration.preserveAlpha, imageHasAlpha(image) {
      return .png
    }
    return configuration.outputFormat
  }

  private static func imageHasAlpha(_ image: UIImage) -> Bool {
    guard let alpha = image.cgImage?.alphaInfo else { return false }
    switch alpha {
    case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly:
      return true
    default:
      return false
    }
  }

  private static func write(data: Data, fileExtension: String, tempStore: FKPhotoTempFileStore) throws -> URL {
    let url = try FKPhotoTempFileStore.makeUniqueURL(fileExtension: fileExtension)
    try data.write(to: url, options: .atomic)
    tempStore.register(url)
    return url
  }

  private static func validateVideoSize(_ bytes: Int, configuration: FKPhotoPickerConfiguration) throws {
    if let max = configuration.video.maxVideoBytes, bytes > max {
      throw FKPhotoPickerError.fileTooLarge(bytes: bytes, max: max)
    }
  }

  private static func generateVideoThumbnail(for url: URL) async throws -> UIImage? {
    let asset = AVURLAsset(url: url)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    let time = CMTime(seconds: 0, preferredTimescale: 600)
    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
    return UIImage(cgImage: cgImage)
  }

  private static func pixelSize(of image: UIImage) -> CGSize {
    guard let cgImage = image.cgImage else {
      return CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    }
    return CGSize(width: cgImage.width, height: cgImage.height)
  }
}

// MARK: - Delivery helpers

private extension FKPhotoPickerDelivery {
  var includesImage: Bool {
    switch self {
    case .image, .imageAndData, .imageAndFileURL:
      return true
    case .compressedData, .fileURL:
      return false
    }
  }

  var includesData: Bool {
    switch self {
    case .compressedData, .imageAndData:
      return true
    case .image, .fileURL, .imageAndFileURL:
      return false
    }
  }

  var includesFileURL: Bool {
    switch self {
    case .fileURL, .imageAndFileURL:
      return true
    case .image, .compressedData, .imageAndData:
      return false
    }
  }
}

// MARK: - HEIC encoding

private extension UIImage {
  func heicData(compressionQuality: CGFloat) -> Data? {
    guard let cgImage else { return nil }
    let output = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(output, UTType.heic.identifier as CFString, 1, nil)
    else {
      return nil
    }
    let options: [CFString: Any] = [
      kCGImageDestinationLossyCompressionQuality: compressionQuality,
    ]
    CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { return nil }
    return output as Data
  }
}

// MARK: - Image decoding

private enum FKPhotoPickerImageDecoder {
  static func decode(
    data: Data,
    targetWidth: Double?,
    targetHeight: Double?,
    scale: CGFloat
  ) throws -> UIImage {
    guard !data.isEmpty else {
      throw FKPhotoPickerError.processingFailed(underlyingDescription: "Empty image data.")
    }

    let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
    guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
      throw FKPhotoPickerError.processingFailed(underlyingDescription: "Invalid image source.")
    }

    guard CGImageSourceGetCount(source) > 0 else {
      throw FKPhotoPickerError.processingFailed(underlyingDescription: "Image source is empty.")
    }

    if let maxPixelSize = maxPixelSize(targetWidth: targetWidth, targetHeight: targetHeight, source: source, scale: scale) {
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
      throw FKPhotoPickerError.processingFailed(underlyingDescription: "Image decode failed.")
    }

    var image = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    if let targetSize = resolvedTargetSize(targetWidth: targetWidth, targetHeight: targetHeight, imageSize: image.size),
       targetSize != image.size {
      image = image.fk_resized(to: targetSize) ?? image
    }
    return image
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
      return Int(width * Double(scale))
    case let (nil, height?):
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
      return CGSize(width: width, height: imageSize.height / imageSize.width * width)
    case let (nil, height?):
      guard imageSize.height > 0 else { return nil }
      return CGSize(width: imageSize.width / imageSize.height * height, height: height)
    case (nil, nil):
      return nil
    }
  }
}
