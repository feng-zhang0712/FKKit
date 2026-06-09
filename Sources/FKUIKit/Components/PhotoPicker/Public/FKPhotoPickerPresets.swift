/// Factory presets for common pick flows.
public enum FKPhotoPickerPresets {
  /// Single avatar: library or camera, 1024 px max, JPEG 0.9.
  public static func avatar() -> FKPhotoPickerConfiguration {
    FKPhotoPickerConfiguration(
      source: .libraryOrCamera,
      mediaTypes: .images,
      selection: FKPhotoPickerSelectionPolicy(limit: 1),
      delivery: .imageAndFileURL,
      compression: FKPhotoCompressionOptions(
        maxPixelDimension: 1024,
        jpegQuality: 0.9,
        outputFormat: .jpeg,
        stripLocationEXIF: true
      ),
      camera: FKPhotoPickerCameraOptions(allowsEditing: true)
    )
  }

  /// Chat attachments: multi-select images with compressed file URLs.
  public static func chatAttachments(max: Int = 9) -> FKPhotoPickerConfiguration {
    FKPhotoPickerConfiguration(
      source: .photoLibrary,
      mediaTypes: .images,
      selection: FKPhotoPickerSelectionPolicy(limit: max),
      delivery: .imageAndFileURL,
      compression: FKPhotoCompressionOptions(
        maxPixelDimension: 2048,
        jpegQuality: 0.85,
        outputFormat: .jpeg,
        stripLocationEXIF: true
      )
    )
  }

  /// Document scan from camera with GPS stripped.
  public static func documentScan() -> FKPhotoPickerConfiguration {
    FKPhotoPickerConfiguration(
      source: .camera,
      mediaTypes: .images,
      selection: FKPhotoPickerSelectionPolicy(limit: 1),
      delivery: .imageAndFileURL,
      compression: FKPhotoCompressionOptions(
        maxPixelDimension: 4096,
        jpegQuality: 0.92,
        outputFormat: .jpeg,
        stripLocationEXIF: true
      ),
      camera: FKPhotoPickerCameraOptions(allowsEditing: false)
    )
  }

  /// High-quality single library image with minimal compression.
  public static func highQualitySingle() -> FKPhotoPickerConfiguration {
    FKPhotoPickerConfiguration(
      source: .photoLibrary,
      mediaTypes: .images,
      selection: FKPhotoPickerSelectionPolicy(limit: 1),
      delivery: .imageAndFileURL,
      compression: FKPhotoCompressionOptions(
        maxPixelDimension: nil,
        jpegQuality: 0.95,
        outputFormat: .matchSource,
        stripLocationEXIF: false
      )
    )
  }
}

/// Global default configuration applied when callers omit an explicit configuration.
public enum FKPhotoPickerDefaults {
  public nonisolated(unsafe) static var configuration: FKPhotoPickerConfiguration = .init()
}
