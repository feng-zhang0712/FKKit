import Photos
import PhotosUI

enum FKMediaGalleryLivePhotoLoader {
  @MainActor
  static func loadLivePhoto(
    localIdentifier: String,
    targetSize: CGSize,
    onProgressiveLivePhoto: (@MainActor (PHLivePhoto) -> Void)? = nil
  ) async throws -> PHLivePhoto {
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
    guard let asset = assets.firstObject else {
      throw FKMediaGalleryError.imageLoadFailed(index: 0, description: "Live Photo asset not found.")
    }
    return try await withCheckedThrowingContinuation { continuation in
      let options = PHLivePhotoRequestOptions()
      options.isNetworkAccessAllowed = true
      options.deliveryMode = .opportunistic
      var didResume = false
      PHImageManager.default().requestLivePhoto(
        for: asset,
        targetSize: targetSize,
        contentMode: .aspectFit,
        options: options
      ) { livePhoto, info in
        if (info?[PHImageCancelledKey] as? Bool) == true {
          return
        }
        if let error = info?[PHImageErrorKey] as? Error {
          guard !didResume else { return }
          didResume = true
          continuation.resume(throwing: error)
          return
        }
        guard let livePhoto else {
          guard !didResume else { return }
          didResume = true
          continuation.resume(
            throwing: FKMediaGalleryError.imageLoadFailed(index: 0, description: "Empty Live Photo.")
          )
          return
        }
        let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
        if isDegraded {
          Task { @MainActor in
            onProgressiveLivePhoto?(livePhoto)
          }
          return
        }
        guard !didResume else { return }
        didResume = true
        continuation.resume(returning: livePhoto)
      }
    }
  }
}
