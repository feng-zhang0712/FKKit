import FKCoreKit
import PhotosUI
import UIKit

@MainActor
final class FKMediaGalleryLivePhotoPageCell: UICollectionViewCell, FKMediaGalleryPageView {
  static let reuseIdentifier = "FKMediaGalleryLivePhotoPageCell"

  var pageIndex = 0
  var onLoadFailed: ((FKMediaGalleryError) -> Void)?

  private let livePhotoView = PHLivePhotoView()
  private var loadTask: Task<Void, Never>?
  private var boundAssetIdentifier: String?

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .clear
    livePhotoView.translatesAutoresizingMaskIntoConstraints = false
    livePhotoView.contentMode = .scaleAspectFit
    contentView.addSubview(livePhotoView)
    NSLayoutConstraint.activate([
      livePhotoView.topAnchor.constraint(equalTo: contentView.topAnchor),
      livePhotoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      livePhotoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      livePhotoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    loadTask?.cancel()
    loadTask = nil
    boundAssetIdentifier = nil
    livePhotoView.stopPlayback()
    livePhotoView.livePhoto = nil
  }

  var isBlockingHorizontalPaging: Bool { false }
  var isBlockingInteractiveDismiss: Bool { false }

  func prepareForDisplay(
    item: FKMediaGalleryItem,
    configuration: FKMediaGalleryConfiguration,
    imageLoader: (any FKImageLoading)?,
    placeholder: UIImage?
  ) {
    livePhotoView.isMuted = configuration.livePhoto.isMutedDuringPlayback
    guard case let .livePhoto(source) = item.kind else { return }
    guard case let .assetLocalIdentifier(identifier) = source else { return }
    boundAssetIdentifier = identifier
    loadLivePhoto(identifier: identifier, configuration: configuration)
  }

  func didBecomeCurrent(configuration: FKMediaGalleryConfiguration) {
    livePhotoView.isMuted = configuration.livePhoto.isMutedDuringPlayback
    if livePhotoView.livePhoto == nil, let identifier = boundAssetIdentifier {
      loadLivePhoto(identifier: identifier, configuration: configuration)
    }
  }

  func didEndDisplaying() {
    loadTask?.cancel()
    livePhotoView.stopPlayback()
    releaseRetainedImageContent()
  }

  func galleryWillDismiss() {
    livePhotoView.stopPlayback()
  }

  func releaseRetainedImageContent() {
    loadTask?.cancel()
    livePhotoView.livePhoto = nil
  }

  func makeInteractiveDismissSnapshot() -> UIView? {
    livePhotoView.snapshotView(afterScreenUpdates: false)
  }

  func interactiveDismissVisualContent() -> (image: UIImage, contentSize: CGSize)? {
    guard let image = FKMediaGalleryDismissVisualRenderer.image(from: livePhotoView) else { return nil }
    let contentSize = FKMediaGalleryLayoutMath.resolvedImageSize(from: image)
    guard contentSize.width > 0, contentSize.height > 0 else { return nil }
    return (image, contentSize)
  }

  private func loadLivePhoto(identifier: String, configuration: FKMediaGalleryConfiguration) {
    loadTask?.cancel()
    loadTask = Task { @MainActor in
      let screenScale = FKMediaGalleryImageLoadingMath.screenScale(for: livePhotoView)
      let targetSize = FKMediaGalleryImageLoadingMath.decodeTargetSize(
        bounds: livePhotoView.bounds.size,
        screenScale: screenScale,
        maximumZoomScale: 1,
        isCurrentPage: true
      )
      do {
        let livePhoto = try await FKMediaGalleryLivePhotoLoader.loadLivePhoto(
          localIdentifier: identifier,
          targetSize: targetSize,
          onProgressiveLivePhoto: { [weak self] preview in
            self?.livePhotoView.livePhoto = preview
          }
        )
        guard !Task.isCancelled else { return }
        livePhotoView.livePhoto = livePhoto
      } catch {
        guard !Task.isCancelled else { return }
        onLoadFailed?(.imageLoadFailed(index: pageIndex, description: error.localizedDescription))
      }
    }
  }
}
