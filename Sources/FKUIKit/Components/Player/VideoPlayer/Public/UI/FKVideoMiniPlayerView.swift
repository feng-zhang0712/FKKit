import UIKit

/// Compact floating mini player shell (Phase 3/4).
@MainActor
public final class FKVideoMiniPlayerView: UIView {

  public var onExpand: (() -> Void)?
  public var onClose: (() -> Void)?

  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let playPauseButton = UIButton(type: .system)
  private let closeButton = UIButton(type: .system)
  private let progressView = UIProgressView(progressViewStyle: .bar)
  private weak var player: FKVideoPlayer?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.secondarySystemBackground
    layer.cornerRadius = 12
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.2
    layer.shadowRadius = 8

    titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
    titleLabel.textColor = .label
    addSubview(titleLabel)

    subtitleLabel.font = .systemFont(ofSize: 11, weight: .regular)
    subtitleLabel.textColor = .secondaryLabel
    addSubview(subtitleLabel)

    progressView.progressTintColor = .systemBlue
    addSubview(progressView)

    playPauseButton.tintColor = .label
    playPauseButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)
    addSubview(playPauseButton)

    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.tintColor = .secondaryLabel
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    addSubview(closeButton)

    let tap = UITapGestureRecognizer(target: self, action: #selector(expandTapped))
    addGestureRecognizer(tap)
    isAccessibilityElement = false
    playPauseButton.accessibilityLabel = FKVideoPlayerStrings.play
    closeButton.accessibilityLabel = FKVideoPlayerStrings.close
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    closeButton.frame = CGRect(x: 8, y: 10, width: 32, height: 32)
    playPauseButton.frame = CGRect(x: bounds.width - 44, y: 8, width: 36, height: 36)
    titleLabel.frame = CGRect(x: 44, y: 8, width: bounds.width - 96, height: 18)
    subtitleLabel.frame = CGRect(x: 44, y: 26, width: bounds.width - 96, height: 14)
    progressView.frame = CGRect(x: 12, y: bounds.height - 6, width: bounds.width - 24, height: 3)
  }

  public func bind(player: FKVideoPlayer) {
    self.player = player
    titleLabel.text = player.currentItem?.title ?? "Video"
    subtitleLabel.text = player.isLive ? FKVideoPlayerStrings.live : nil
    subtitleLabel.isHidden = subtitleLabel.text == nil
    updatePlayIcon()
    updateProgress()
  }

  public func updateProgress() {
    guard let player else { return }
    let duration = max(player.duration, 1)
    progressView.progress = Float(player.currentTime / duration)
    updatePlayIcon()
  }

  private func updatePlayIcon() {
    let playing = player?.state == .playing || player?.state == .buffering
    let name = playing ? "pause.fill" : "play.fill"
    playPauseButton.setImage(UIImage(systemName: name), for: .normal)
    playPauseButton.accessibilityLabel = playing ? FKVideoPlayerStrings.pause : FKVideoPlayerStrings.play
  }

  @objc
  private func toggle() {
    player?.togglePlayPause()
    updatePlayIcon()
  }

  @objc
  private func closeTapped() {
    player?.stop()
    onClose?()
    isHidden = true
  }

  @objc
  private func expandTapped() {
    onExpand?()
  }
}
