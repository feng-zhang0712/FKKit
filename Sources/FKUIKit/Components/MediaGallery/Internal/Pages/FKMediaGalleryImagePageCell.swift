import FKCoreKit
import UIKit

@MainActor
final class FKMediaGalleryImagePageCell: UICollectionViewCell, FKMediaGalleryPageView {
  static let reuseIdentifier = "FKMediaGalleryImagePageCell"

  var pageIndex = 0
  var onLoadFailed: ((FKMediaGalleryError) -> Void)?

  private let zoomScrollView = FKMediaGalleryZoomScrollView()
  private var boundItemID: String?
  private var resumeImageSource: FKMediaGalleryImageSource?
  private var fullSizeTask: Task<Void, Never>?
  private var photoAssetTask: Task<Void, Never>?

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .clear
    zoomScrollView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(zoomScrollView)
    NSLayoutConstraint.activate([
      zoomScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
      zoomScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      zoomScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      zoomScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    fullSizeTask?.cancel()
    photoAssetTask?.cancel()
    fullSizeTask = nil
    photoAssetTask = nil
    boundItemID = nil
    resumeImageSource = nil
    zoomScrollView.resetContent()
  }

  var isBlockingHorizontalPaging: Bool {
    zoomScrollView.isZoomedBeyondMinimum
  }

  var isBlockingInteractiveDismiss: Bool {
    zoomScrollView.isZoomedBeyondMinimum
  }

  func prepareForDisplay(
    item: FKMediaGalleryItem,
    configuration: FKMediaGalleryConfiguration,
    imageLoader: (any FKImageLoading)?,
    placeholder: UIImage?
  ) {
    boundItemID = item.id
    zoomScrollView.apply(configuration: configuration.zoom)
    zoomScrollView.configureImageLoader(imageLoader)
    guard case let .image(source) = item.kind else {
      resumeImageSource = nil
      return
    }
    resumeImageSource = source
    loadImage(source: source, configuration: configuration, placeholder: placeholder)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    zoomScrollView.setNeedsLayout()
  }

  func didBecomeCurrent(configuration: FKMediaGalleryConfiguration) {
    zoomScrollView.relayoutForNewImage()
    if !zoomScrollView.hasDisplayedImage, let source = resumeImageSource {
      loadImage(source: source, configuration: configuration, placeholder: nil)
    }
  }

  func didEndDisplaying() {
    fullSizeTask?.cancel()
    photoAssetTask?.cancel()
    releaseRetainedImageContent()
  }

  func galleryWillDismiss() {
    fullSizeTask?.cancel()
    photoAssetTask?.cancel()
    zoomScrollView.cancelRemoteLoading()
  }

  func releaseRetainedImageContent() {
    fullSizeTask?.cancel()
    photoAssetTask?.cancel()
    zoomScrollView.releaseDisplayedImage()
  }

  func makeInteractiveDismissSnapshot() -> UIView? {
    guard !isBlockingInteractiveDismiss else { return nil }
    return zoomScrollView.snapshotView(afterScreenUpdates: false)
  }

  func interactiveDismissVisualContent() -> (image: UIImage, contentSize: CGSize)? {
    guard !isBlockingInteractiveDismiss,
          let image = zoomScrollView.dismissVisualImage else {
      return nil
    }
    let contentSize = FKMediaGalleryLayoutMath.resolvedImageSize(from: image)
    guard contentSize.width > 0, contentSize.height > 0 else { return nil }
    return (image, contentSize)
  }

  private func loadImage(
    source: FKMediaGalleryImageSource,
    configuration: FKMediaGalleryConfiguration,
    placeholder: UIImage?
  ) {
    if let inline = FKMediaGalleryItemResolver.inlineImage(for: source) {
      zoomScrollView.setLocalImage(inline)
      return
    }
    if let bundleImage = FKMediaGalleryItemResolver.bundleImage(for: source) {
      zoomScrollView.setLocalImage(bundleImage)
      return
    }

    let imageView = zoomScrollView.fkImageView
    imageView.apply { config in
      config.loading.loadingPresentation.progressMode = configuration.progressiveLoading.showsProgressIndicator
        ? .activityIndicator
        : .none
    }

    if let assetID = FKMediaGalleryItemResolver.photoAssetIdentifier(for: source) {
      if let placeholder {
        imageView.setImage(placeholder, animated: false)
      }
      let expectedItemID = boundItemID
      photoAssetTask = Task { @MainActor in
        do {
          let screenScale = FKMediaGalleryImageLoadingMath.screenScale(for: zoomScrollView)
          let targetSize = FKMediaGalleryImageLoadingMath.decodeTargetSize(
            bounds: zoomScrollView.bounds.size,
            screenScale: screenScale,
            maximumZoomScale: configuration.zoom.maximumZoomScale,
            isCurrentPage: true
          )
          let image = try await FKMediaGalleryPhotoAssetLoader.loadImage(
            localIdentifier: assetID,
            targetSize: targetSize,
            onProgressiveImage: { [weak self] progressiveImage in
              guard let self, self.boundItemID == expectedItemID else { return }
              imageView.setImage(progressiveImage, animated: false)
              self.zoomScrollView.relayoutForNewImage()
            }
          )
          guard !Task.isCancelled, self.boundItemID == expectedItemID else { return }
          imageView.setImage(image, animated: true)
          zoomScrollView.relayoutForNewImage()
        } catch {
          guard !Task.isCancelled else { return }
          onLoadFailed?(.imageLoadFailed(index: pageIndex, description: error.localizedDescription))
        }
      }
      return
    }

    switch source {
    case let .url(url, options):
      if configuration.progressiveLoading.enabled, let thumbURL = options.thumbnailURL {
        imageView.cacheKey = options.thumbnailCacheKey ?? options.cacheKey
        imageView.load(url: thumbURL, placeholder: placeholder)
        loadFullSizeURL(
          url,
          options: options,
          crossfade: configuration.progressiveLoading.fullSizeCrossfadeDuration,
          configuration: configuration
        )
      } else {
        imageView.cacheKey = options.cacheKey
        imageView.load(url: url, placeholder: placeholder)
      }
    default:
      break
    }

    imageView.onStateChange = { [weak self] state in
      guard let self else { return }
      if case .success = state {
        self.zoomScrollView.relayoutForNewImage()
      }
      if case let .failure(reason) = state {
        let message: String
        switch reason {
        case .network: message = FKImageViewI18n.networkMessage
        case .decode: message = FKImageViewI18n.decodeMessage
        case .offline: message = FKImageViewI18n.offlineMessage
        case .cancelled: return
        case let .custom(text): message = text ?? FKImageViewI18n.networkMessage
        }
        self.onLoadFailed?(.imageLoadFailed(index: self.pageIndex, description: message))
      }
    }
  }

  private func loadFullSizeURL(
    _ url: URL,
    options: FKMediaGalleryImageRequestOptions,
    crossfade: TimeInterval,
    configuration: FKMediaGalleryConfiguration
  ) {
    fullSizeTask?.cancel()
    let expectedItemID = boundItemID
    fullSizeTask = Task { @MainActor in
      let loader = zoomScrollView.fkImageView.imageLoader ?? FKImageLoader.shared
      let screenScale = FKMediaGalleryImageLoadingMath.screenScale(for: zoomScrollView)
      let targetSize = FKMediaGalleryImageLoadingMath.decodeTargetSize(
        bounds: zoomScrollView.bounds.size,
        screenScale: screenScale,
        maximumZoomScale: configuration.zoom.maximumZoomScale,
        isCurrentPage: true
      )
      let request = FKImageLoadRequest(
        url: url,
        targetSize: targetSize,
        cacheKey: options.cacheKey
      )
      do {
        let image = try await loader.loadImage(for: request)
        guard !Task.isCancelled, self.boundItemID == expectedItemID else { return }
        let animated = crossfade > 0 && !UIAccessibility.isReduceMotionEnabled
        zoomScrollView.fkImageView.setImage(image, animated: animated)
        zoomScrollView.relayoutForNewImage()
      } catch {
        guard !Task.isCancelled else { return }
        onLoadFailed?(.imageLoadFailed(index: pageIndex, description: error.localizedDescription))
      }
    }
  }
}
