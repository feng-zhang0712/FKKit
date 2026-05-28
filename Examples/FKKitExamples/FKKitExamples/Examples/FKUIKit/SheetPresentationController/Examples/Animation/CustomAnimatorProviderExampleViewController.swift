import UIKit
import FKUIKit

/// Replaces built-in transitions with a custom ``FKSheetPresentationAnimatorProviding`` implementation.
final class CustomAnimatorProviderExampleViewController: FKSheetPresentationExamplePageViewController {
  private let animatorProvider = FKExampleFadeSheetAnimatorProvider()

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Custom animator provider",
      subtitle: "Supply fully custom presentation and dismissal animators.",
      notes: """
      Set `configuration.animation.customAnimatorProvider` when property animators are not enough.
      Interactive dismiss still uses FK's interactor when swipe dismiss is enabled.
      """
    )

    addPrimaryButton(title: "Present with fade animator") { [weak self] in
      guard let self else { return }
      var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fixed(300), .full]
      configuration.animation.customAnimatorProvider = self.animatorProvider
      _ = FKSheetPresentationExampleHelpers.present(from: self, title: "Custom animator", configuration: configuration)
    }
  }
}

@MainActor
private final class FKExampleFadeSheetAnimatorProvider: FKSheetPresentationAnimatorProviding {
  func makePresentationAnimator() -> UIViewControllerAnimatedTransitioning {
    FKExampleFadeSheetAnimator(isPresentation: true)
  }

  func makeDismissalAnimator() -> UIViewControllerAnimatedTransitioning {
    FKExampleFadeSheetAnimator(isPresentation: false)
  }
}

@MainActor
private final class FKExampleFadeSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  private let isPresentation: Bool

  init(isPresentation: Bool) {
    self.isPresentation = isPresentation
  }

  func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
    0.34
  }

  func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
    let key: UITransitionContextViewControllerKey = isPresentation ? .to : .from
    guard let controller = transitionContext.viewController(forKey: key),
          let animatingView = transitionContext.view(forKey: isPresentation ? .to : .from) else {
      transitionContext.completeTransition(false)
      return
    }

    let containerView = transitionContext.containerView
    let finalFrame = transitionContext.finalFrame(for: controller)

    if isPresentation {
      containerView.addSubview(animatingView)
      animatingView.frame = finalFrame
      animatingView.alpha = 0
    }

    UIView.animate(
      withDuration: transitionDuration(using: transitionContext),
      delay: 0,
      options: [.curveEaseInOut]
    ) {
      animatingView.alpha = self.isPresentation ? 1 : 0
    } completion: { finished in
      transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
    }
  }
}
