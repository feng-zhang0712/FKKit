import UIKit

/// Displays live status and estimated latency.
@MainActor
public final class FKVideoLiveBadgeView: UIView {

  private let label = UILabel()
  private var goLiveButton: UIButton?

  public var onGoLiveTapped: (() -> Void)?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
    layer.cornerRadius = 4
    clipsToBounds = true

    label.font = .systemFont(ofSize: 12, weight: .bold)
    label.textColor = .white
    label.text = FKUIKitI18n.string("fkuikit.video.live_badge")
    addSubview(label)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    label.sizeToFit()
    label.frame.origin = CGPoint(x: 8, y: (bounds.height - label.bounds.height) / 2)
    if let goLiveButton {
      goLiveButton.sizeToFit()
      goLiveButton.frame = CGRect(
        x: label.frame.maxX + 8,
        y: 0,
        width: goLiveButton.bounds.width + 8,
        height: bounds.height
      )
    }
  }

  public override var intrinsicContentSize: CGSize {
    CGSize(width: 120, height: 28)
  }

  public func update(isLive: Bool, latencySeconds: TimeInterval?) {
    isHidden = !isLive
    let showsGoLive = isLive && (latencySeconds ?? 0) > 1
    if showsGoLive {
      mountGoLiveButton()
    } else {
      unmountGoLiveButton()
    }
    if let latencySeconds, latencySeconds > 1 {
      label.text = FKUIKitI18n.format("fkuikit.video.live_latency", latencySeconds)
    } else {
      label.text = FKUIKitI18n.string("fkuikit.video.live_badge")
    }
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  @objc
  private func goLive() {
    onGoLiveTapped?()
  }

  private func mountGoLiveButton() -> UIButton {
    if let goLiveButton { return goLiveButton }
    let button = UIButton(type: .system)
    button.setTitle(FKUIKitI18n.string("fkuikit.video.go_live"), for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
    button.addTarget(self, action: #selector(goLive), for: .touchUpInside)
    goLiveButton = button
    addSubview(button)
    return button
  }

  private func unmountGoLiveButton() {
    goLiveButton?.removeFromSuperview()
    goLiveButton = nil
  }
}
