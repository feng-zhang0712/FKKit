import QuartzCore
import UIKit
import FKCoreKit

/// Reusable pulse animation layer for online presence (respects Reduce Motion).
final class FKPresencePulseLayer: CALayer {
  private let pulseLayer = CALayer()
  private var isAnimating = false
  private nonisolated(unsafe) var reduceMotionObserver: NSObjectProtocol?
  /// Retains the notification target so `@Sendable` observer closures do not capture `self` directly.
  private let reduceMotionTarget = ReduceMotionTarget()

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
    reduceMotionTarget.layer = self
    reduceMotionObserver = NotificationCenter.default.addObserver(
      forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [reduceMotionTarget] _ in
      reduceMotionTarget.handle()
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
    guard !FKMainActorUIKitBridge.isReduceMotionEnabled() else { return }
    isAnimating = true
    restartAnimation()
  }

  func stopAnimating() {
    isAnimating = false
    pulseLayer.removeAllAnimations()
    pulseLayer.opacity = 0
    pulseLayer.transform = CATransform3DIdentity
  }

  fileprivate func handleReduceMotionStatusChange() {
    if FKMainActorUIKitBridge.isReduceMotionEnabled() {
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

/// Bridges Reduce Motion notifications into the pulse layer without capturing a non-Sendable `CALayer` in a `@Sendable` closure.
private final class ReduceMotionTarget: @unchecked Sendable {
  weak var layer: FKPresencePulseLayer?

  func handle() {
    layer?.handleReduceMotionStatusChange()
  }
}
