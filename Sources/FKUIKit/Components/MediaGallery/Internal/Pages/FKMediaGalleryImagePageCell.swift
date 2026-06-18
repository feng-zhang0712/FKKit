import FKCoreKit
import UIKit

@MainActor
final class FKMediaGalleryImagePageCell: UICollectionViewCell, FKMediaGalleryPageView {
  static let reuseIdentifier = "FKMediaGalleryImagePageCell"

  var pageIndex = 0
  var onLoadFailed: ((FKMediaGalleryError) -> Void)?

  private let zoomScrollView = FKMediaGalleryZoomScrollView()
  private var boundItemID: String?
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
    zoomScrollView.resetContent()
  }

  var isBlockingHorizontalPaging: Bool {
    zoomScrollView.isZoomedBeyondMinimum
  }

  var isBlockingInteractiveDismiss: Bool {
    zoomScrollView.isZoomedBeyondMinimum
  }

  func setPagingEnabled(_ enabled: Bool) {}

  func prepareForDisplay(
    item: FKMediaGalleryItem,
    configuration: FKMediaGalleryConfiguration,
    imageLoader: (any FKImageLoading)?,
    placeholder: UIImage?
  ) {
    boundItemID = item.id
    zoomScrollView.apply(configuration: configuration.zoom)
    zoomScrollView.configureImageLoader(imageLoader)
    guard case let .image(source) = item.kind else { return }
    loadImage(source: source, configuration: configuration, placeholder: placeholder)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    zoomScrollView.setNeedsLayout()
  }

  func didBecomeCurrent(configuration: FKMediaGalleryConfiguration) {
    zoomScrollView.relayoutForNewImage()
  }

  func didEndDisplaying() {
    fullSizeTask?.cancel()
    photoAssetTask?.cancel()
    zoomScrollView.cancelRemoteLoading()
    zoomScrollView.resetZoom(animated: false)
  }

  func galleryWillDismiss() {
    fullSizeTask?.cancel()
    photoAssetTask?.cancel()
    zoomScrollView.cancelRemoteLoading()
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
      photoAssetTask = Task { @MainActor in
        do {
          let scale = UIScreen.main.scale
          let size = CGSize(
            width: zoomScrollView.bounds.width * scale,
            height: zoomScrollView.bounds.height * scale
          )
          let image = try await FKMediaGalleryPhotoAssetLoader.loadImage(
            localIdentifier: assetID,
            targetSize: size
          )
          guard !Task.isCancelled else { return }
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
          crossfade: configuration.progressiveLoading.fullSizeCrossfadeDuration
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
    crossfade: TimeInterval
  ) {
    fullSizeTask?.cancel()
    fullSizeTask = Task { @MainActor in
      let loader = zoomScrollView.fkImageView.imageLoader ?? FKImageLoader.shared
      let request = FKImageLoadRequest(
        url: url,
        targetSize: zoomScrollView.bounds.size,
        cacheKey: options.cacheKey
      )
      do {
        let image = try await loader.loadImage(for: request)
        guard !Task.isCancelled else { return }
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
