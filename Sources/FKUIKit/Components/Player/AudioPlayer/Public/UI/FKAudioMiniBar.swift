import UIKit

/// Compact bottom mini player bar for tab-based apps.
@MainActor
public final class FKAudioMiniBar: UIView {

  private let contentView = FKAudioPlayerView(style: .miniBar)
  private weak var player: FKAudioPlayer?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .secondarySystemBackground
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.12
    layer.shadowRadius = 8
    layer.shadowOffset = CGSize(width: 0, height: -2)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(contentView)
    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: topAnchor),
      contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    let tap = UITapGestureRecognizer(target: self, action: #selector(openNowPlaying))
    addGestureRecognizer(tap)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: 60)
  }

  public func bind(player: FKAudioPlayer) {
    self.player = player
    contentView.bind(player: player)
  }

  /// Refreshes transport state from the bound player (call after late binding or modal dismiss).
  public func syncFromPlayer() {
    guard let player else { return }
    if let item = player.currentItem {
      reload(for: item)
    }
    handleStateChange(player.state)
    updateProgress(current: player.currentTime, duration: player.duration)
  }

  public func reload(for item: FKAudioItem) {
    contentView.reload(for: item)
  }

  public func handleStateChange(_ state: FKMediaPlaybackState) {
    contentView.handleStateChange(state)
  }

  public func updateProgress(current: TimeInterval, duration: TimeInterval) {
    contentView.updateProgress(current: current, duration: duration, buffered: [])
  }

  public func reset() {
    contentView.reset()
  }

  @objc
  private func openNowPlaying() {
    guard let player, let host = nearestViewController() else { return }
    let controller = FKAudioPlayerViewController(player: player)
    host.present(controller, animated: true)
  }

  private func nearestViewController() -> UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let vc = current as? UIViewController { return vc }
      responder = current.next
    }
    return nil
  }
}
