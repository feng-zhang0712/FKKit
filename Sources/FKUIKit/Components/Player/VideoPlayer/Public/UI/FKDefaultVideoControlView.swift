import UIKit

/// Default transport controls for ``FKVideoPlayerView``.
@MainActor
public final class FKDefaultVideoControlView: UIView, FKVideoPlayerControlView {

  public var isControlsLocked = false

  private weak var player: FKVideoPlayer?

  private let playPauseButton = UIButton(type: .system)
  private let fullscreenButton = UIButton(type: .system)
  private let settingsButton = UIButton(type: .system)
  private let currentTimeLabel = UILabel()
  private let durationLabel = UILabel()
  private let progressSlider = UISlider()
  private let bufferProgressView = UIProgressView(progressViewStyle: .bar)

  private var isScrubbing = false
  private var showsRemainingTime = false
  private var themeTint: UIColor = .white
  private let thumbnailPreview = FKVideoThumbnailSeekPreview()
  private var thumbnailTask: Task<Void, Never>?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.black.withAlphaComponent(0.35)

    playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    playPauseButton.tintColor = .white
    playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)

    fullscreenButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
    fullscreenButton.tintColor = .white
    fullscreenButton.addTarget(self, action: #selector(toggleFullscreen), for: .touchUpInside)

    settingsButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
    settingsButton.tintColor = .white
    settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

    for label in [currentTimeLabel, durationLabel] {
      label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
      label.textColor = .white
    }
    currentTimeLabel.text = "00:00"
    durationLabel.text = "00:00"

    progressSlider.minimumValue = 0
    progressSlider.maximumValue = 1
    progressSlider.addTarget(self, action: #selector(sliderBegan), for: .touchDown)
    progressSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    progressSlider.addTarget(self, action: #selector(sliderEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])

    bufferProgressView.progressTintColor = UIColor.white.withAlphaComponent(0.35)
    bufferProgressView.trackTintColor = UIColor.white.withAlphaComponent(0.15)

    [
      playPauseButton, settingsButton, fullscreenButton,
      currentTimeLabel, durationLabel, bufferProgressView, progressSlider,
    ].forEach {
      addSubview($0)
    }
  }

  func applyTheme(_ tint: UIColor) {
    themeTint = tint
    playPauseButton.tintColor = tint
    fullscreenButton.tintColor = tint
    settingsButton.tintColor = tint
  }

  func configure(showsRemainingTime: Bool) {
    self.showsRemainingTime = showsRemainingTime
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let safe = safeAreaInsets
    let height = bounds.height
    let width = bounds.width

    playPauseButton.frame = CGRect(x: safe.left + 12, y: (height - 44) / 2, width: 44, height: 44)
    fullscreenButton.frame = CGRect(x: width - safe.right - 56, y: (height - 44) / 2, width: 44, height: 44)
    settingsButton.frame = CGRect(x: fullscreenButton.frame.minX - 48, y: (height - 44) / 2, width: 44, height: 44)

    currentTimeLabel.frame = CGRect(x: playPauseButton.frame.maxX + 4, y: 14, width: 52, height: 20)
    durationLabel.frame = CGRect(x: settingsButton.frame.minX - 56, y: 14, width: 52, height: 20)

    let sliderX = currentTimeLabel.frame.maxX + 8
    let sliderWidth = durationLabel.frame.minX - sliderX - 8
    progressSlider.frame = CGRect(x: sliderX, y: 28, width: sliderWidth, height: 24)
    bufferProgressView.frame = CGRect(x: sliderX + 2, y: 38, width: sliderWidth - 4, height: 4)
  }

  public func bind(player: FKVideoPlayer) {
    self.player = player
    configure(showsRemainingTime: player.configuration.ui.showsRemainingTime)
    applyTheme(player.configuration.ui.resolvedTintColor(traitCollection: traitCollection))
    configureAccessibility()
    if effectiveUserInterfaceLayoutDirection == .rightToLeft {
      semanticContentAttribute = .forceRightToLeft
    }
  }

  private func configureAccessibility() {
    playPauseButton.accessibilityLabel = FKVideoPlayerStrings.play
    fullscreenButton.accessibilityLabel = FKVideoPlayerStrings.fullscreen
    settingsButton.accessibilityLabel = FKVideoPlayerStrings.settings
    progressSlider.accessibilityLabel = FKVideoPlayerStrings.progress
  }

  public func update(
    state: FKMediaPlaybackState,
    currentTime: TimeInterval,
    duration: TimeInterval,
    buffered: [ClosedRange<TimeInterval>],
    isLive: Bool,
    liveLatency: TimeInterval?
  ) {
    _ = liveLatency
    if !isScrubbing {
      let maxDuration = max(duration, 1)
      progressSlider.value = Float(currentTime / maxDuration)
      bufferProgressView.progress = Float(bufferedCoverage(buffered, duration: duration))
    }

    currentTimeLabel.text = formatTime(currentTime)
    playPauseButton.accessibilityLabel =
      (state == .playing || state == .buffering) ? FKVideoPlayerStrings.pause : FKVideoPlayerStrings.play

    if isLive {
      durationLabel.text = FKVideoPlayerStrings.live
      progressSlider.isEnabled = !isControlsLocked
    } else if showsRemainingTime, duration > 0 {
      durationLabel.text = "-\(formatTime(max(0, duration - currentTime)))"
      progressSlider.isEnabled = duration > 0 && !isControlsLocked
    } else {
      durationLabel.text = formatTime(duration)
      progressSlider.isEnabled = duration > 0 && !isControlsLocked
    }

    switch state {
    case .playing, .buffering:
      playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    default:
      playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
  }

  public func setControlsVisible(_ visible: Bool, animated: Bool) {
    let alpha: CGFloat = visible ? 1 : 0
    let animations = { self.alpha = alpha }
    if animated {
      UIView.animate(withDuration: 0.25, animations: animations)
    } else {
      animations()
    }
  }

  // MARK: - Actions

  @objc
  private func togglePlayPause() {
    guard !isControlsLocked else { return }
    player?.boundView?.noteControlsInteraction()
    player?.togglePlayPause()
  }

  @objc
  private func toggleFullscreen() {
    guard !isControlsLocked else { return }
    player?.boundView?.noteControlsInteraction()
    player?.boundView?.toggleFullscreen()
  }

  @objc
  private func openSettings() {
    guard !isControlsLocked,
          let player,
          let host = nearestViewController() else { return }
    player.boundView?.noteControlsInteraction()
    FKVideoSettingsMenu.present(from: settingsButton, in: host, player: player)
  }

  private func nearestViewController() -> UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let vc = current as? UIViewController { return vc }
      responder = current.next
    }
    return nil
  }

  @objc
  private func sliderBegan() {
    isScrubbing = true
    player?.boundView?.noteControlsInteraction()
  }

  @objc
  private func sliderChanged() {
    guard let player else { return }
    let target = TimeInterval(progressSlider.value) * max(player.duration, 1)
    currentTimeLabel.text = formatTime(target)
    updateThumbnailPreview(at: target)
  }

  @objc
  private func sliderEnded() {
    guard let player else { return }
    let target = TimeInterval(progressSlider.value) * max(player.duration, 1)
    thumbnailPreview.hide()
    thumbnailTask?.cancel()
    player.seek(to: target) { [weak self] _ in
      self?.isScrubbing = false
    }
  }

  private func updateThumbnailPreview(at time: TimeInterval) {
    guard let player, let provider = player.thumbnailProvider else {
      thumbnailPreview.hide()
      return
    }
    let centerX = progressSlider.frame.minX + CGFloat(progressSlider.value) * progressSlider.frame.width
    thumbnailTask?.cancel()
    thumbnailTask = Task { @MainActor in
      let image = await provider.thumbnail(at: time)
      guard !Task.isCancelled else { return }
      thumbnailPreview.show(image: image, time: time, centerX: centerX, in: self)
    }
  }

  private func bufferedCoverage(_ ranges: [ClosedRange<TimeInterval>], duration: TimeInterval) -> Double {
    guard duration > 0 else { return 0 }
    let end = ranges.map(\.upperBound).max() ?? 0
    return min(1, end / duration)
  }

  private func formatTime(_ time: TimeInterval) -> String {
    guard time.isFinite, time >= 0 else { return "00:00" }
    let total = Int(time)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
