import Photos
import UIKit

enum FKMediaGalleryPhotoAssetLoader {
  @MainActor
  static func loadImage(localIdentifier: String, targetSize: CGSize) async throws -> UIImage {
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
    guard let asset = assets.firstObject else {
      throw FKMediaGalleryError.imageLoadFailed(index: 0, description: "Photo asset not found.")
    }
    return try await withCheckedThrowingContinuation { continuation in
      let options = PHImageRequestOptions()
      options.isNetworkAccessAllowed = true
      options.deliveryMode = .highQualityFormat
      options.resizeMode = .fast
      PHImageManager.default().requestImage(
        for: asset,
        targetSize: targetSize,
        contentMode: .aspectFit,
        options: options
      ) { image, info in
        if let error = info?[PHImageErrorKey] as? Error {
          continuation.resume(throwing: error)
          return
        }
        guard let image else {
          continuation.resume(throwing: FKMediaGalleryError.imageLoadFailed(index: 0, description: "Empty image."))
          return
        }
        continuation.resume(returning: image)
      }
    }
  }
}
