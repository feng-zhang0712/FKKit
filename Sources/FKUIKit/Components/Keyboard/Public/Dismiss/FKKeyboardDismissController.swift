import UIKit

/// Installs a tap gesture that dismisses the keyboard when the user taps outside text inputs.
@MainActor
public final class FKKeyboardDismissController: NSObject, UIGestureRecognizerDelegate {
  /// View that hosts the dismiss gesture.
  public weak var containerView: UIView?

  /// Dismiss configuration.
  public var configuration: FKKeyboardDismissConfiguration {
    didSet { gesture?.cancelsTouchesInView = configuration.cancelsTouchesInView }
  }

  /// Weak so the recognizer’s strong target reference cannot form a retain cycle with this controller.
  private weak var gesture: UITapGestureRecognizer?
  private var isInstalled = false

  /// Creates a dismiss controller for `containerView`.
  public init(containerView: UIView, configuration: FKKeyboardDismissConfiguration = .init()) {
    self.containerView = containerView
    self.configuration = configuration
    super.init()
  }

  /// Adds the tap gesture to the container. Idempotent.
  public func start() {
    guard !isInstalled, let containerView else { return }
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    tap.cancelsTouchesInView = configuration.cancelsTouchesInView
    tap.delegate = self
    containerView.addGestureRecognizer(tap)
    gesture = tap
    isInstalled = true
  }

  /// Removes the tap gesture.
  public func stop() {
    if let gesture, let containerView {
      containerView.removeGestureRecognizer(gesture)
    }
    gesture = nil
    isInstalled = false
  }

  @objc
  private func handleTap() {
    containerView?.endEditing(true)
  }

  /// Allows the dismiss tap only when the touch is outside the active text input (when configured).
  public func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldReceive touch: UITouch
  ) -> Bool {
    guard configuration.ignoresTapsInsideFirstResponder else { return true }
    guard let view = touch.view else { return true }
    if view is UITextField || view is UITextView {
      return false
    }
    if let responder = containerView?.fk_findFirstResponder(), view.isDescendant(of: responder) {
      return false
    }
    return true
  }
}
