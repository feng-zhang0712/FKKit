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
    teardownPlayer()
    playerView.setPosterImage(nil)
    playerView.resetChrome()
  }

  var isBlockingHorizontalPaging: Bool { isScrubbing }
  var isBlockingInteractiveDismiss: Bool { isScrubbing }

  func setPagingEnabled(_ enabled: Bool) {}

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
    controlView.allowsScrubbing = configuration.video.allowsScrubbing
    guard case let .video(source) = item.kind else { return }
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

    let videoItem = FKMediaGalleryItemResolver.videoItem(for: source, itemID: item.id)
    if videoItem.posterURL == nil, let placeholder {
      playerView.setPosterImage(placeholder)
    }
    player.load(videoItem)
    player.delegate = self
    refreshDoubleTapGesture(configuration: configuration)
  }

  func didBecomeCurrent(configuration: FKMediaGalleryConfiguration) {
    sessionConfiguration = configuration
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

  private func teardownPlayer() {
    player?.stop()
    player = nil
    playerView.setPosterImage(nil)
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
    player?.togglePlayPause()
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
