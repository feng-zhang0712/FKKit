import UIKit

@MainActor
extension FKContainerSheetPresentationController {
  // MARK: - Keyboard Observation

  /// Subscribes to keyboard frame updates once per presentation lifecycle.
  func startKeyboardTrackingIfNeeded() {
    keyboardCoordinator.startTracking(isEnabled: configuration.keyboardAvoidance.isEnabled) { [weak self] endFrame, duration, curveRaw in
      self?.handleKeyboard(endFrameScreen: endFrame, duration: duration, curveRaw: curveRaw)
    }
  }

  /// Removes keyboard observers and restores any insets/transforms we touched.
  func stopKeyboardTracking() {
    keyboardCoordinator.stopTracking(restoreScrollIn: presentedViewController.view)
    wrapperView.transform = .identity
  }

  // MARK: - Keyboard Application

  /// Converts keyboard frame to container space and updates cached inset.
  func handleKeyboard(endFrameScreen: CGRect, duration: Double, curveRaw: Int) {
    guard let containerView else { return }
    guard configuration.keyboardAvoidance.isEnabled else { return }

    let options = UIView.AnimationOptions(rawValue: UInt(curveRaw << 16))
    keyboardCoordinator.updateBottomInset(
      endFrameScreen: endFrameScreen,
      in: containerView,
      additionalBottomInset: configuration.keyboardAvoidance.additionalBottomInset
    )

    let animations: () -> Void = { [weak self] in
      self?.applyKeyboardAvoidance(in: containerView)
    }

    let strategy = configuration.keyboardAvoidance.strategy
    let shouldAnimate = (strategy == .interactive) ? true : duration > 0
    if shouldAnimate {
      UIView.animate(withDuration: duration, delay: 0, options: [options, .allowUserInteraction], animations: animations)
    } else {
      animations()
    }
  }

  /// Applies keyboard offset via either content insets or container translation.
  func applyKeyboardAvoidance(in containerView: UIView) {
    guard configuration.keyboardAvoidance.isEnabled else { return }
    // Avoid fighting live interactive dismiss / detent pans (they own frame/transform).
    guard !sheetPanCoordinator.isPanningSheet,
          !centerPanCoordinator.isInteractivelyDragging,
          !keepsInteractiveFrameForDismissal else { return }

    switch configuration.keyboardAvoidance.strategy {
    case .disabled:
      return
    case .adjustContentInsets:
      guard let scroll = resolveKeyboardTargetScrollView() else { return }
      keyboardCoordinator.applyContentInsetAvoidance(to: scroll)
    case .adjustContainer, .interactive:
      keyboardCoordinator.translateWrapperAvoidingKeyboard(wrapperView, in: containerView)
    }
  }
}
