import UIKit

@MainActor
extension FKOverlayPresentationViewController {
  func embedContent(_ contentController: UIViewController) {
    addChild(contentController)
    contentController.view.translatesAutoresizingMaskIntoConstraints = false
    contentContainerView.addSubview(contentController.view)
    NSLayoutConstraint.activate([
      contentController.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
      contentController.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
      contentController.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
      contentController.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
    ])
    contentController.didMove(toParent: self)
    hostedContentView = contentController.view
  }

  func updateLayout(animated: Bool, duration: TimeInterval, options: UIView.AnimationOptions) {
    let apply = {
      self.backdropView.configure(with: self.configuration.backdropStyle)
      self.wrapperView.frame = self.frameOfWrapper()
      self.layoutContent()
      self.applyAppearance()
      self.updatePassthroughHitTesting()
    }
    if animated {
      UIView.animate(
        withDuration: max(0, duration),
        delay: 0,
        options: [options, .beginFromCurrentState, .allowUserInteraction],
        animations: apply
      )
    } else {
      apply()
    }
  }

  func animatePresentation(isPresentation: Bool, animated: Bool, completion: @escaping () -> Void) {
    if isPresentation {
      updateLayout(animated: false, duration: 0, options: .curveLinear)
    } else {
      updatePassthroughHitTesting()
    }

    let baseFrame = frameOfWrapper()
    FKSheetPresentationOverlayTransition.animatePresentation(
      configuration: configuration,
      isPresentation: isPresentation,
      animated: animated,
      backdropView: backdropView,
      wrapperView: wrapperView,
      baseFrame: baseFrame,
      completion: completion
    )
  }

  /// Animates from the current interactive sheet state, then requests host dismissal without a second transition.
  func performInteractiveDismiss(velocityY: CGFloat) {
    skipsDismissPresentationAnimation = true
    let baseFrame = frameOfWrapper()
    FKSheetPresentationOverlayTransition.animateInteractiveDismiss(
      configuration: configuration,
      backdropView: backdropView,
      wrapperView: wrapperView,
      baseFrame: baseFrame,
      dismissalVelocityY: velocityY
    ) { [weak self] in
      self?.onRequestDismiss?()
    }
  }
}
