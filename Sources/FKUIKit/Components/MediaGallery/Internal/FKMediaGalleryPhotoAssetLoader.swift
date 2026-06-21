import Photos
import UIKit

enum FKMediaGalleryPhotoAssetLoader {
  @MainActor
  static func loadImage(
    localIdentifier: String,
    targetSize: CGSize,
    onProgressiveImage: (@MainActor (UIImage) -> Void)? = nil
  ) async throws -> UIImage {
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
    guard let asset = assets.firstObject else {
      throw FKMediaGalleryError.imageLoadFailed(index: 0, description: "Photo asset not found.")
    }
    return try await requestImage(
      for: asset,
      targetSize: targetSize,
      deliveryMode: .opportunistic,
      onProgressiveImage: onProgressiveImage
    )
  }

  @MainActor
  static func loadVideoPoster(localIdentifier: String, targetSize: CGSize) async throws -> UIImage {
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
    guard let asset = assets.firstObject else {
      throw FKMediaGalleryError.imageLoadFailed(index: 0, description: "Photo asset not found.")
    }
    return try await requestImage(
      for: asset,
      targetSize: targetSize,
      deliveryMode: .fastFormat,
      onProgressiveImage: nil
    )
  }

  @MainActor
  private static func requestImage(
    for asset: PHAsset,
    targetSize: CGSize,
    deliveryMode: PHImageRequestOptionsDeliveryMode,
    onProgressiveImage: (@MainActor (UIImage) -> Void)?
  ) async throws -> UIImage {
    try await withCheckedThrowingContinuation { continuation in
      let options = PHImageRequestOptions()
      options.isNetworkAccessAllowed = true
      options.deliveryMode = deliveryMode
      options.resizeMode = .fast
      var didResume = false
      PHImageManager.default().requestImage(
        for: asset,
        targetSize: targetSize,
        contentMode: .aspectFit,
        options: options
      ) { image, info in
        if (info?[PHImageCancelledKey] as? Bool) == true {
          return
        }
        if let error = info?[PHImageErrorKey] as? Error {
          guard !didResume else { return }
          didResume = true
          continuation.resume(throwing: error)
          return
        }
        guard let image else {
          guard !didResume else { return }
          didResume = true
          continuation.resume(
            throwing: FKMediaGalleryError.imageLoadFailed(index: 0, description: "Empty image.")
          )
          return
        }
        let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
        if isDegraded {
          Task { @MainActor in
            onProgressiveImage?(image)
          }
          return
        }
        guard !didResume else { return }
        didResume = true
        continuation.resume(returning: image)
      }
    }
  }
}
