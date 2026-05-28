import UIKit

/// Observes keyboard frame changes and applies avoidance for sheet presentation hosts.
@MainActor
final class FKSheetPresentationKeyboardCoordinator {
  private(set) var bottomInset: CGFloat = 0
  private var observers: [NSObjectProtocol] = []
  private var originalScrollInsets: (content: UIEdgeInsets, indicator: UIEdgeInsets)?

  /// Subscribes to keyboard notifications when enabled.
  func startTracking(
    isEnabled: Bool,
    onKeyboardChange: @escaping (_ endFrameScreen: CGRect, _ duration: TimeInterval, _ curveRaw: Int) -> Void
  ) {
    guard isEnabled, observers.isEmpty else { return }

    let center = NotificationCenter.default
    let handler: (Notification) -> Void = { note in
      let userInfo = note.userInfo ?? [:]
      let endFrameScreen = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
      let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue
        ?? UIView.AnimationCurve.easeInOut.rawValue
      Task { @MainActor in
        onKeyboardChange(endFrameScreen, duration, curveRaw)
      }
    }

    observers.append(center.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil,
      queue: .main,
      using: handler
    ))
    observers.append(center.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main,
      using: handler
    ))
  }

  /// Removes observers and restores scroll insets when applicable.
  func stopTracking(restoreScrollIn root: UIView?) {
    let center = NotificationCenter.default
    observers.forEach { center.removeObserver($0) }
    observers.removeAll()

    if let scroll = FKSheetScrollTracking.findPrimaryScrollView(in: root), let originalScrollInsets {
      scroll.contentInset = originalScrollInsets.content
      scroll.scrollIndicatorInsets = originalScrollInsets.indicator
    }
    originalScrollInsets = nil
    bottomInset = 0
  }

  /// Updates cached bottom inset from a keyboard end frame in screen coordinates.
  func updateBottomInset(
    endFrameScreen: CGRect,
    in containerView: UIView,
    additionalBottomInset: CGFloat
  ) {
    let endFrameInWindow = containerView.window?.convert(endFrameScreen, from: nil) ?? endFrameScreen
    let endFrame = containerView.convert(endFrameInWindow, from: containerView.window)
    let intersection = containerView.bounds.intersection(endFrame)
    let keyboardHeight = intersection.isNull ? 0 : intersection.height
    let safeBottom = containerView.safeAreaInsets.bottom
    bottomInset = max(0, keyboardHeight - safeBottom + additionalBottomInset)
  }

  /// Applies content inset keyboard avoidance to the resolved scroll view.
  func applyContentInsetAvoidance(to scroll: UIScrollView) {
    if originalScrollInsets == nil {
      originalScrollInsets = (scroll.contentInset, scroll.scrollIndicatorInsets)
    }
    let base = originalScrollInsets ?? (scroll.contentInset, scroll.scrollIndicatorInsets)
    scroll.contentInset = .init(
      top: base.content.top,
      left: base.content.left,
      bottom: base.content.bottom + bottomInset,
      right: base.content.right
    )
    scroll.scrollIndicatorInsets = .init(
      top: base.indicator.top,
      left: base.indicator.left,
      bottom: base.indicator.bottom + bottomInset,
      right: base.indicator.right
    )
  }

  /// Translates a wrapper view upward when it would overlap the keyboard region.
  func translateWrapperAvoidingKeyboard(_ wrapperView: UIView, in containerView: UIView) {
    let keyboardTopY = containerView.bounds.height - bottomInset
    let overlap = max(0, wrapperView.frame.maxY - keyboardTopY)
    wrapperView.transform = CGAffineTransform(translationX: 0, y: -overlap)
  }

  /// Offsets a proposed presentation frame upward to clear the keyboard for anchor layouts.
  func frameAvoidingKeyboard(_ frame: CGRect, in hostView: UIView) -> CGRect {
    guard bottomInset > 0 else { return frame }
    let keyboardTopY = hostView.bounds.height - bottomInset
    let overlap = max(0, frame.maxY - keyboardTopY)
    return frame.offsetBy(dx: 0, dy: -overlap)
  }
}
