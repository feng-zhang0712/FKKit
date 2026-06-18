import FKCoreKit
import UIKit

@MainActor
final class FKMediaGalleryVideoPageCell: UICollectionViewCell, FKMediaGalleryPageView {
  static let reuseIdentifier = "FKMediaGalleryVideoPageCell"

  var pageIndex = 0
  var onLoadFailed: ((FKMediaGalleryError) -> Void)?
  var onRequestFullScreenPlayer: ((FKVideoPlayer) -> Void)?

  private let playerView = FKVideoPlayerView(loadsDefaultControlView: false)
  private let controlView = FKMediaGalleryVideoControlView()
  private(set) var player: FKVideoPlayer?
  var embeddedPlayerView: FKVideoPlayerView { playerView }
  private var isScrubbing = false
  private var sessionConfiguration: FKMediaGalleryConfiguration?
  private var doubleTapRecognizer: UITapGestureRecognizer?
  private var longPressRecognizer: UILongPressGestureRecognizer?
  private var boundVideoSource: FKMediaGalleryVideoSource?
  private var boundItemID: String?
  private var posterTask: Task<Void, Never>?
  private var imageLoader: (any FKImageLoading)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .black
    playerView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(playerView)
    NSLayoutConstraint.activate([
      playerView.topAnchor.constraint(equalTo: contentView.topAnchor),
      playerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      playerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      playerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    playerView.setDefaultControlView(controlView)
    controlView.onScrubbingChanged = { [weak self] scrubbing in
      self?.isScrubbing = scrubbing
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    removeDoubleTapGesture()
    removeLongPressGesture()
    posterTask?.cancel()
    posterTask = nil
    boundVideoSource = nil
    boundItemID = nil
    imageLoader = nil
    teardownPlayer()
    playerView.setPosterImage(nil)
    playerView.resetChrome()
  }

  var isBlockingHorizontalPaging: Bool { isScrubbing }
  var isBlockingInteractiveDismiss: Bool { isScrubbing }

  override func layoutSubviews() {
    super.layoutSubviews()
    let bottomInset = window?.safeAreaInsets.bottom ?? safeAreaInsets.bottom
    controlView.contentBottomInset = bottomInset
    playerView.layoutIfNeeded()
    if bottomInset > 0, let control = playerView.controlView {
      control.frame = CGRect(
        x: 0,
        y: playerView.bounds.height - 80 - bottomInset,
        width: playerView.bounds.width,
        height: 80 + bottomInset
      )
    }
  }

  override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    setNeedsLayout()
  }

  func prepareForDisplay(
    item: FKMediaGalleryItem,
    configuration: FKMediaGalleryConfiguration,
    imageLoader: (any FKImageLoading)?,
    placeholder: UIImage?
  ) {
    sessionConfiguration = configuration
    self.imageLoader = imageLoader
    controlView.allowsScrubbing = configuration.video.allowsScrubbing
    guard case let .video(source) = item.kind else { return }
    boundVideoSource = source
    boundItemID = item.id
    loadPoster(for: source, itemID: item.id, placeholder: placeholder)
    refreshDoubleTapGesture(configuration: configuration)
    refreshLongPressGesture()
  }

  func didBecomeCurrent(configuration: FKMediaGalleryConfiguration) {
    sessionConfiguration = configuration
    ensurePlayerIfNeeded()
    guard let player else { return }
    let videoConfig = configuration.video
    guard videoConfig.autoplayCurrentVideo else { return }
    guard FKMediaGalleryNetworkPolicy.allowsAutoplay(for: videoConfig.cellularAutoplayPolicy) else {
      return
    }
    player.play()
  }

  func didEndDisplaying() {
    guard let player, let configuration = sessionConfiguration else {
      teardownPlayer()
      return
    }
    if configuration.video.pauseWhenScrolling {
      player.pause()
    }
    if configuration.video.teardownPlayerWhenOffscreen {
      teardownPlayer()
    }
  }

  func galleryWillDismiss() {
    teardownPlayer()
  }

  func releaseRetainedImageContent() {}

  func makeInteractiveDismissSnapshot() -> UIView? {
    guard !isBlockingInteractiveDismiss else { return nil }
    return playerView.snapshotView(afterScreenUpdates: false)
  }

  func interactiveDismissVisualContent() -> (image: UIImage, contentSize: CGSize)? {
    guard !isBlockingInteractiveDismiss else { return nil }
    return FKMediaGalleryDismissVisualRenderer.videoMediaContent(
      playerView: playerView,
      player: player
    )
  }

  private func ensurePlayerIfNeeded() {
    guard player == nil,
          let source = boundVideoSource,
          let itemID = boundItemID,
          let configuration = sessionConfiguration else {
      return
    }
    if FKMediaGalleryItemResolver.bundleVideoURL(for: source) == nil,
       case .bundleResource = source {
      onLoadFailed?(.videoLoadFailed(index: pageIndex, underlying: "Bundle video resource not found."))
      return
    }
    let videoConfig = configuration.video
    var playerConfiguration = videoConfig.playerConfiguration
    if videoConfig.loopsCurrentVideo {
      playerConfiguration.media.playback.loopMode = .one
    }
    let player = FKVideoPlayer(configuration: playerConfiguration)
    player.isMuted = videoConfig.mutedByDefault
    player.coordinator.photoAssetResolver = FKMediaPhotoLibraryAssetResolver()
    self.player = player
    player.bind(to: playerView)
    playerView.apply(uiConfiguration: playerConfiguration.ui)

    let videoItem = FKMediaGalleryItemResolver.videoItem(for: source, itemID: itemID)
    player.load(videoItem)
    player.delegate = self
  }

  private func loadPoster(
    for source: FKMediaGalleryVideoSource,
    itemID: String,
    placeholder: UIImage?
  ) {
    posterTask?.cancel()
    let expectedItemID = itemID
    if let assetID = FKMediaGalleryItemResolver.photoAssetVideoIdentifier(for: source) {
      if let placeholder {
        playerView.setPosterImage(placeholder)
      }
      posterTask = Task { @MainActor in
        let screenScale = FKMediaGalleryImageLoadingMath.screenScale(for: contentView)
        let targetSize = FKMediaGalleryImageLoadingMath.decodeTargetSize(
          bounds: bounds.size,
          screenScale: screenScale,
          maximumZoomScale: 1,
          isCurrentPage: false
        )
        if let image = try? await FKMediaGalleryPhotoAssetLoader.loadVideoPoster(
          localIdentifier: assetID,
          targetSize: targetSize
        ), !Task.isCancelled, self.boundItemID == expectedItemID {
          playerView.setPosterImage(image)
        }
      }
      return
    }
    let videoItem = FKMediaGalleryItemResolver.videoItem(for: source, itemID: itemID)
    if videoItem.posterURL == nil {
      playerView.setPosterImage(placeholder)
      return
    }
    if let placeholder {
      playerView.setPosterImage(placeholder)
    }
    guard let posterURL = videoItem.posterURL else { return }
    let loader = imageLoader ?? FKImageLoader.shared
    posterTask = Task { @MainActor in
      let screenScale = FKMediaGalleryImageLoadingMath.screenScale(for: contentView)
      let targetSize = FKMediaGalleryImageLoadingMath.decodeTargetSize(
        bounds: bounds.size,
        screenScale: screenScale,
        maximumZoomScale: 1,
        isCurrentPage: false
      )
      let request = FKImageLoadRequest(url: posterURL, targetSize: targetSize)
      do {
        let image = try await loader.loadImage(for: request)
        guard !Task.isCancelled, self.boundItemID == expectedItemID else { return }
        playerView.setPosterImage(image)
      } catch {
        guard !Task.isCancelled else { return }
      }
    }
  }

  private func teardownPlayer() {
    player?.stop()
    player = nil
  }

  private func refreshDoubleTapGesture(configuration: FKMediaGalleryConfiguration) {
    removeDoubleTapGesture()
    guard configuration.interaction.videoDoubleTapTogglesPlayback else { return }
    let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
    recognizer.numberOfTapsRequired = 2
    contentView.addGestureRecognizer(recognizer)
    doubleTapRecognizer = recognizer
  }

  private func removeDoubleTapGesture() {
    if let doubleTapRecognizer {
      contentView.removeGestureRecognizer(doubleTapRecognizer)
    }
    doubleTapRecognizer = nil
  }

  @objc private func handleDoubleTap() {
    ensurePlayerIfNeeded()
    player?.togglePlayPause()
  }

  private func refreshLongPressGesture() {
    removeLongPressGesture()
    let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    recognizer.minimumPressDuration = 0.45
    contentView.addGestureRecognizer(recognizer)
    longPressRecognizer = recognizer
  }

  private func removeLongPressGesture() {
    if let longPressRecognizer {
      contentView.removeGestureRecognizer(longPressRecognizer)
    }
    longPressRecognizer = nil
  }

  @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
    guard recognizer.state == .began else { return }
    ensurePlayerIfNeeded()
    guard let player else { return }
    onRequestFullScreenPlayer?(player)
  }
}

extension FKMediaGalleryVideoPageCell: FKVideoPlayerDelegate {
  func videoPlayer(_ player: FKVideoPlayer, didChangeState state: FKMediaPlaybackState) {
    switch state {
    case .playing:
      playerView.setPosterImage(nil)
    case .failed:
      break
    default:
      break
    }
  }

  func videoPlayer(_ player: FKVideoPlayer, didFail error: FKMediaError) {
    onLoadFailed?(.videoLoadFailed(index: pageIndex, underlying: error.localizedDescription))
  }

  func videoPlayerDidFinish(_ player: FKVideoPlayer) {
    if sessionConfiguration?.video.loopsCurrentVideo == true {
      player.seek(to: 0)
      player.play()
    }
  }
}
