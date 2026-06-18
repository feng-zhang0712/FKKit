import UIKit

/// Slim transport controls for gallery video pages.
@MainActor
final class FKMediaGalleryVideoControlView: UIView, FKVideoPlayerControlView {
  var isControlsLocked = false
  var onScrubbingChanged: ((Bool) -> Void)?

  var contentBottomInset: CGFloat = 0
  var allowsScrubbing = true {
    didSet {
      progressSlider.isEnabled = allowsScrubbing
      progressSlider.isUserInteractionEnabled = allowsScrubbing
    }
  }

  private weak var player: FKVideoPlayer?
  private let playPauseButton = UIButton(type: .system)
  private let progressSlider = UISlider()
  private let bufferProgressView = UIProgressView(progressViewStyle: .bar)
  private var isScrubbing = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.black.withAlphaComponent(0.35)

    playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    playPauseButton.tintColor = .white
    playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)

    progressSlider.minimumValue = 0
    progressSlider.maximumValue = 1
    progressSlider.addTarget(self, action: #selector(sliderBegan), for: .touchDown)
    progressSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    progressSlider.addTarget(self, action: #selector(sliderEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])

    bufferProgressView.progressTintColor = UIColor.white.withAlphaComponent(0.35)
    bufferProgressView.trackTintColor = UIColor.white.withAlphaComponent(0.15)

    [playPauseButton, bufferProgressView, progressSlider].forEach { addSubview($0) }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let inset: CGFloat = 16
    let bottomPadding = max(contentBottomInset, max(safeAreaInsets.bottom, 12))
    let controlBottom = bounds.height - bottomPadding
    playPauseButton.frame = CGRect(x: inset, y: controlBottom - 44, width: 44, height: 44)
    progressSlider.frame = CGRect(
      x: playPauseButton.frame.maxX + 8,
      y: controlBottom - 34,
      width: bounds.width - playPauseButton.frame.maxX - inset - 8,
      height: 24
    )
    bufferProgressView.frame = CGRect(
      x: progressSlider.frame.minX,
      y: progressSlider.frame.midY - 1,
      width: progressSlider.frame.width,
      height: 2
    )
  }

  func bind(player: FKVideoPlayer) {
    self.player = player
  }

  func update(
    state: FKMediaPlaybackState,
    currentTime: TimeInterval,
    duration: TimeInterval,
    buffered: [ClosedRange<TimeInterval>],
    isLive: Bool,
    liveLatency: TimeInterval?
  ) {
    guard !isScrubbing else { return }
    let iconName: String
    switch state {
    case .playing, .buffering:
      iconName = "pause.fill"
    default:
      iconName = "play.fill"
    }
    playPauseButton.setImage(UIImage(systemName: iconName), for: .normal)
    if duration > 0 {
      progressSlider.value = Float(currentTime / duration)
      let bufferedEnd = buffered.last?.upperBound ?? 0
      bufferProgressView.progress = Float(bufferedEnd / duration)
    } else {
      progressSlider.value = 0
      bufferProgressView.progress = 0
    }
  }

  func setControlsVisible(_ visible: Bool, animated: Bool) {
    let alpha: CGFloat = visible ? 1 : 0
    if animated {
      UIView.animate(withDuration: 0.2) { self.alpha = alpha }
    } else {
      self.alpha = alpha
    }
  }

  @objc private func togglePlayPause() {
    player?.togglePlayPause()
  }

  @objc private func sliderBegan() {
    isScrubbing = true
    onScrubbingChanged?(true)
  }

  @objc private func sliderChanged() {
    guard let player, player.duration > 0 else { return }
    let time = TimeInterval(progressSlider.value) * player.duration
    player.seek(to: time)
  }

  @objc private func sliderEnded() {
    isScrubbing = false
    onScrubbingChanged?(false)
  }
}
