import UIKit

/// Slide/fade transitions for ``FKActionSheetViewController``.
@MainActor
final class FKActionSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  private let isPresenting: Bool
  private let configuration: FKActionSheetPresentationConfiguration
  private weak var actionSheetViewController: FKActionSheetViewController?

  init(
    isPresenting: Bool,
    configuration: FKActionSheetPresentationConfiguration,
    actionSheetViewController: FKActionSheetViewController?
  ) {
    self.isPresenting = isPresenting
    self.configuration = configuration
    self.actionSheetViewController = actionSheetViewController
    super.init()
  }

  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    if configuration.respectsReduceMotion, UIAccessibility.isReduceMotionEnabled {
      return 0.2
    }
    return isPresenting ? 0.42 : 0.34
  }

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    let from = transitionContext.viewController(forKey: .from)
    let to = transitionContext.viewController(forKey: .to)
    let sheet = (isPresenting ? to : from) as? FKActionSheetViewController
    let containerView = transitionContext.containerView

    if isPresenting {
      guard let sheet, let presentedView = transitionContext.view(forKey: .to) else {
        transitionContext.completeTransition(false)
        return
      }
      containerView.addSubview(presentedView)
      let targetFrame = containerView.bounds.width > 0
        ? containerView.bounds
        : transitionContext.finalFrame(for: sheet)
      presentedView.frame = targetFrame
      presentedView.layoutIfNeeded()
      sheet.prepareForPresentationAnimation()

      let reduceMotion = configuration.respectsReduceMotion && UIAccessibility.isReduceMotionEnabled
      if reduceMotion {
        sheet.setPresentationProgress(1, animated: false)
        transitionContext.completeTransition(true)
        return
      }

      sheet.setPresentationProgress(0, animated: false)
      animate(
        duration: transitionDuration(using: transitionContext),
        animations: {
          sheet.setPresentationProgress(1, animated: false)
        },
        completion: { finished in
          transitionContext.completeTransition(finished)
        }
      )
    } else {
      guard let sheet else {
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        return
      }

      let reduceMotion = configuration.respectsReduceMotion && UIAccessibility.isReduceMotionEnabled
      if reduceMotion {
        sheet.setPresentationProgress(0, animated: false)
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        return
      }

      animate(
        duration: transitionDuration(using: transitionContext),
        animations: {
          sheet.setPresentationProgress(0, animated: false)
        },
        completion: { finished in
          if finished, !transitionContext.transitionWasCancelled {
            transitionContext.view(forKey: .from)?.removeFromSuperview()
          }
          transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
        }
      )
    }
  }

  private func animate(
    duration: TimeInterval,
    animations: @escaping () -> Void,
    completion: @escaping (Bool) -> Void
  ) {
    UIView.animate(
      withDuration: duration,
      delay: 0,
      usingSpringWithDamping: isPresenting ? 0.86 : 1,
      initialSpringVelocity: isPresenting ? 0.3 : 0,
      options: [.curveEaseInOut, .allowUserInteraction],
      animations: animations,
      completion: completion
    )
  }
}
