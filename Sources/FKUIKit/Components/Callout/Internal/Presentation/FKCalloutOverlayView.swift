import UIKit

/// Full-window host that positions the bubble and optionally observes outside taps.
final class FKCalloutOverlayView: UIView, UIGestureRecognizerDelegate {
  private let backdropView = FKCalloutBackdropView()
  let bubbleView: FKCalloutBubbleView

  var onTapOutside: (() -> Void)?

  private var tapOutsideToDismiss = true
  private var passesThroughOutsideTouches = false
  private weak var hostWindow: UIWindow?
  private var outsideTapRecognizer: UITapGestureRecognizer?

  init(bubbleView: FKCalloutBubbleView) {
    self.bubbleView = bubbleView
    super.init(frame: .zero)
    backgroundColor = .clear
    isUserInteractionEnabled = true
    addSubview(backdropView)
    addSubview(bubbleView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  func updateBackdrop(style: FKCalloutBackdropStyle, spotlightRectInOverlay: CGRect?) {
    backdropView.frame = bounds
    backdropView.update(style: style, spotlightRectInBounds: spotlightRectInOverlay)
  }

  /// Installs dismiss gestures. When ``passesThroughOutsideTouches`` is true, outside taps reach views
  /// behind the overlay; an optional window-level recognizer still reports outside taps for dismissal.
  func configureInteraction(
    tapOutsideToDismiss: Bool,
    passesThroughOutsideTouches: Bool,
    hostWindow: UIWindow?
  ) {
    teardownInteraction()

    self.tapOutsideToDismiss = tapOutsideToDismiss
    self.passesThroughOutsideTouches = passesThroughOutsideTouches
    self.hostWindow = hostWindow

    guard tapOutsideToDismiss else { return }

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
    tap.delegate = self
    tap.cancelsTouchesInView = false
    if passesThroughOutsideTouches, let hostWindow {
      hostWindow.addGestureRecognizer(tap)
    } else {
      addGestureRecognizer(tap)
    }
    outsideTapRecognizer = tap
  }

  /// Removes any installed outside-tap recognizer.
  func teardownInteraction() {
    guard let outsideTapRecognizer else { return }
    if passesThroughOutsideTouches, let hostWindow {
      hostWindow.removeGestureRecognizer(outsideTapRecognizer)
    } else {
      removeGestureRecognizer(outsideTapRecognizer)
    }
    self.outsideTapRecognizer = nil
  }

  @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
    guard gesture.state == .ended else { return }
    let point = gesture.location(in: bubbleView)
    guard !bubbleView.point(inside: point, with: nil) else { return }
    onTapOutside?()
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    let point = touch.location(in: bubbleView)
    return !bubbleView.point(inside: point, with: nil)
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    passesThroughOutsideTouches
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    backdropView.frame = bounds
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard !isHidden, alpha > 0.01 else { return nil }
    let bubblePoint = convert(point, to: bubbleView)
    if bubbleView.point(inside: bubblePoint, with: event) {
      return bubbleView.hitTest(bubblePoint, with: event)
    }
    if passesThroughOutsideTouches {
      return nil
    }
    if tapOutsideToDismiss {
      return self
    }
    return nil
  }
}
