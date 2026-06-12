import PhotosUI
import UIKit
import UniformTypeIdentifiers

/// Sendable input extracted on the main actor before background processing.
struct FKPhotoPickerProcessingItem: Sendable {
  enum Payload: Sendable {
    case imageData(Data)
    case videoFileURL(URL)
  }

  let assetIdentifier: String?
  let mediaType: FKPhotoPickerMediaType
  let payload: Payload
}

enum FKPhotoPickerInputExtractor {
  @MainActor
  static func items(from pickerResults: [PHPickerResult], configuration: FKPhotoPickerConfiguration) async throws -> [FKPhotoPickerProcessingItem] {
    var output: [FKPhotoPickerProcessingItem] = []
    output.reserveCapacity(pickerResults.count)

    for result in pickerResults {
      if let item = try await item(from: result, configuration: configuration) {
        output.append(item)
      }
    }
    return output
  }

  @MainActor
  static func item(from info: [UIImagePickerController.InfoKey: Any]) throws -> FKPhotoPickerProcessingItem {
    if let mediaURL = info[.mediaURL] as? URL {
      return FKPhotoPickerProcessingItem(
        assetIdentifier: nil,
        mediaType: .video,
        payload: .videoFileURL(mediaURL)
      )
    }

    let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
    guard let image, let data = image.jpegData(compressionQuality: 1) else {
      throw FKPhotoPickerError.unsupportedMediaType
    }

    return FKPhotoPickerProcessingItem(
      assetIdentifier: nil,
      mediaType: .image,
      payload: .imageData(data)
    )
  }

  @MainActor
  private static func item(
    from pickerResult: PHPickerResult,
    configuration: FKPhotoPickerConfiguration
  ) async throws -> FKPhotoPickerProcessingItem? {
    let provider = pickerResult.itemProvider
    let assetIdentifier = pickerResult.assetIdentifier

    if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
      let data = try await loadData(from: provider, typeIdentifier: UTType.movie.identifier)
      let url = try FKPhotoTempFileStore.makeUniqueURL(fileExtension: "mp4")
      try data.write(to: url, options: .atomic)
      return FKPhotoPickerProcessingItem(
        assetIdentifier: assetIdentifier,
        mediaType: .video,
        payload: .videoFileURL(url)
      )
    }

    if provider.hasItemConformingToTypeIdentifier(UTType.livePhoto.identifier),
       configuration.mediaTypes.contains(.livePhotos) {
      switch configuration.livePhoto {
      case .skip:
        return nil
      case .stillImageOnly, .pairedMovieAndStill:
        if provider.canLoadObject(ofClass: UIImage.self) {
          let image = try await loadUIImage(from: provider)
          guard let data = image.jpegData(compressionQuality: 1) else {
            throw FKPhotoPickerError.processingFailed(underlyingDescription: "Live Photo still encoding failed.")
          }
          return FKPhotoPickerProcessingItem(
            assetIdentifier: assetIdentifier,
            mediaType: .livePhoto,
            payload: .imageData(data)
          )
        }
      }
    }

    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      let data = try await loadData(from: provider, typeIdentifier: UTType.image.identifier)
      return FKPhotoPickerProcessingItem(
        assetIdentifier: assetIdentifier,
        mediaType: .image,
        payload: .imageData(data)
      )
    }

    throw FKPhotoPickerError.unsupportedMediaType
  }

  @MainActor
  private static func loadData(from provider: NSItemProvider, typeIdentifier: String) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
      provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
        if let error {
          continuation.resume(throwing: FKPhotoPickerError.processingFailed(underlyingDescription: error.localizedDescription))
          return
        }
        guard let data, !data.isEmpty else {
          continuation.resume(throwing: FKPhotoPickerError.processingFailed(underlyingDescription: "Empty asset data."))
          return
        }
        continuation.resume(returning: data)
      }
    }
  }

  @MainActor
  private static func loadUIImage(from provider: NSItemProvider) async throws -> UIImage {
    try await withCheckedThrowingContinuation { continuation in
      provider.loadObject(ofClass: UIImage.self) { object, error in
        if let error {
          continuation.resume(throwing: FKPhotoPickerError.processingFailed(underlyingDescription: error.localizedDescription))
          return
        }
        guard let image = object as? UIImage else {
          continuation.resume(throwing: FKPhotoPickerError.processingFailed(underlyingDescription: "Could not decode UIImage."))
          return
        }
        continuation.resume(returning: image)
      }
    }
  }
}
