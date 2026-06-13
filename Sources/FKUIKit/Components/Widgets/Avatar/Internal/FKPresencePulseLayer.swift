import QuartzCore
import UIKit

/// Reusable pulse animation layer for online presence (respects Reduce Motion).
final class FKPresencePulseLayer: CALayer {
  private let pulseLayer = CALayer()
  private var isAnimating = false
  private nonisolated(unsafe) var reduceMotionObserver: NSObjectProtocol?

  /// Called on the main queue when Reduce Motion toggles.
  var onReduceMotionStatusChange: (() -> Void)?

  var pulseColor: UIColor = .systemGreen {
    didSet { pulseLayer.backgroundColor = pulseColor.cgColor }
  }

  var pulsePeriod: TimeInterval = 1.5 {
    didSet { if isAnimating { restartAnimation() } }
  }

  override init() {
    super.init()
    pulseLayer.backgroundColor = pulseColor.cgColor
    addSublayer(pulseLayer)
    reduceMotionObserver = NotificationCenter.default.addObserver(
      forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleReduceMotionStatusChange()
    }
  }

  override init(layer: Any) {
    super.init(layer: layer)
    if let source = layer as? FKPresencePulseLayer {
      pulseColor = source.pulseColor
      pulsePeriod = source.pulsePeriod
      isAnimating = source.isAnimating
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  deinit {
    if let reduceMotionObserver {
      NotificationCenter.default.removeObserver(reduceMotionObserver)
    }
  }

  override func layoutSublayers() {
    super.layoutSublayers()
    pulseLayer.frame = bounds
    pulseLayer.cornerRadius = bounds.width / 2
  }

  func startAnimatingIfNeeded() {
    guard !isAnimating else { return }
    guard !UIAccessibility.isReduceMotionEnabled else { return }
    isAnimating = true
    restartAnimation()
  }

  func stopAnimating() {
    isAnimating = false
    pulseLayer.removeAllAnimations()
    pulseLayer.opacity = 0
    pulseLayer.transform = CATransform3DIdentity
  }

  private func handleReduceMotionStatusChange() {
    if UIAccessibility.isReduceMotionEnabled {
      stopAnimating()
    } else if isAnimating {
      restartAnimation()
    } else {
      startAnimatingIfNeeded()
    }
    onReduceMotionStatusChange?()
  }

  private func restartAnimation() {
    pulseLayer.removeAllAnimations()
    pulseLayer.opacity = 0.6
    pulseLayer.transform = CATransform3DIdentity

    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 1
    scale.toValue = 2.2

    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 0.6
    fade.toValue = 0

    let group = CAAnimationGroup()
    group.animations = [scale, fade]
    group.duration = pulsePeriod
    group.repeatCount = .infinity
    group.timingFunction = CAMediaTimingFunction(name: .easeOut)
    pulseLayer.add(group, forKey: "fk.presence.pulse")
  }
}
