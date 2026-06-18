import UIKit

@MainActor
final class FKMediaGalleryTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  enum Mode {
    case hero(FKMediaGalleryHeroTransitionOptions, FKMediaGalleryTransitionSource?)
    case crossDissolve
  }

  private let isPresenting: Bool
  private let mode: Mode

  init(isPresenting: Bool, mode: Mode) {
    self.isPresenting = isPresenting
    self.mode = mode
    super.init()
  }

  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    if UIAccessibility.isReduceMotionEnabled {
      return 0.2
    }
    switch mode {
    case let .hero(options, _):
      return options.duration
    case .crossDissolve:
      return 0.25
    }
  }

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    if UIAccessibility.isReduceMotionEnabled {
      animateCrossDissolve(using: transitionContext)
      return
    }
    switch mode {
    case let .hero(options, source):
      if let source, source.resolvedFrameInWindow() != nil {
        animateHero(using: transitionContext, options: options, source: source)
      } else {
        animateCrossDissolve(using: transitionContext)
      }
    case .crossDissolve:
      animateCrossDissolve(using: transitionContext)
    }
  }

  private func animateCrossDissolve(using transitionContext: UIViewControllerContextTransitioning) {
    let container = transitionContext.containerView
    if isPresenting {
      guard let toView = transitionContext.view(forKey: .to) else {
        transitionContext.completeTransition(false)
        return
      }
      toView.alpha = 0
      container.addSubview(toView)
      UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
        toView.alpha = 1
      }, completion: { finished in
        transitionContext.completeTransition(finished)
      })
    } else {
      guard let fromView = transitionContext.view(forKey: .from) else {
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        return
      }
      UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
        fromView.alpha = 0
      }, completion: { _ in
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
      })
    }
  }

  private func animateHero(
    using transitionContext: UIViewControllerContextTransitioning,
    options: FKMediaGalleryHeroTransitionOptions,
    source: FKMediaGalleryTransitionSource
  ) {
    let container = transitionContext.containerView
    guard
      let galleryView = (isPresenting
        ? transitionContext.viewController(forKey: .to)
        : transitionContext.viewController(forKey: .from))?.view,
      let frame = source.resolvedFrameInWindow()
    else {
      animateCrossDissolve(using: transitionContext)
      return
    }

    let background = UIView(frame: container.bounds)
    background.backgroundColor = UIColor.black.withAlphaComponent(options.backgroundDimmingAlpha)
    background.alpha = isPresenting ? 0 : 1

    let flyingView: UIView
    if let image = resolvedHeroImage(source: source) {
      let imageView = UIImageView(image: image)
      imageView.contentMode = .scaleAspectFit
      flyingView = imageView
    } else if let thumbnailView = source.thumbnailView,
              let snapshot = thumbnailView.snapshotView(afterScreenUpdates: false) {
      flyingView = snapshot
    } else {
      animateCrossDissolve(using: transitionContext)
      return
    }
    flyingView.frame = frame
    flyingView.layer.cornerRadius = source.cornerRadius
    flyingView.clipsToBounds = true

    if isPresenting, let toView = transitionContext.view(forKey: .to) {
      container.addSubview(toView)
      toView.alpha = 0
    }
    container.addSubview(background)
    container.addSubview(flyingView)

    let targetFrame = FKMediaGalleryLayoutMath.aspectFitFrame(
      contentSize: resolvedHeroContentSize(source: source, fallbackBounds: container.bounds),
      in: container.bounds
    )
    let animations = {
      background.alpha = self.isPresenting ? 1 : 0
      flyingView.frame = self.isPresenting ? targetFrame : frame
      flyingView.layer.cornerRadius = self.isPresenting ? 0 : source.cornerRadius
      if self.isPresenting {
        transitionContext.view(forKey: .to)?.alpha = 1
      } else {
        transitionContext.view(forKey: .from)?.alpha = 0
      }
    }

    let duration = transitionDuration(using: transitionContext)
    if options.usesSpringAnimation && !UIAccessibility.isReduceMotionEnabled {
      UIView.animate(
        withDuration: duration,
        delay: 0,
        usingSpringWithDamping: 0.86,
        initialSpringVelocity: 0.4,
        options: [.curveEaseInOut],
        animations: animations
      ) { finished in
        background.removeFromSuperview()
        flyingView.removeFromSuperview()
        transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
      }
    } else {
      UIView.animate(withDuration: duration, animations: animations) { finished in
        background.removeFromSuperview()
        flyingView.removeFromSuperview()
        transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
      }
    }
  }

  private func resolvedHeroImage(source: FKMediaGalleryTransitionSource) -> UIImage? {
    if let image = source.placeholderImage {
      return image
    }
    if let imageView = source.thumbnailView as? UIImageView, let image = imageView.image {
      return image
    }
    if let imageView = source.thumbnailView as? FKImageView, let image = imageView.image {
      return image
    }
    return nil
  }

  private func resolvedHeroContentSize(source: FKMediaGalleryTransitionSource, fallbackBounds: CGRect) -> CGSize {
    if let image = source.placeholderImage {
      return FKMediaGalleryLayoutMath.resolvedImageSize(from: image)
    }
    if let imageView = source.thumbnailView as? UIImageView, let image = imageView.image {
      return FKMediaGalleryLayoutMath.resolvedImageSize(from: image)
    }
    if let imageView = source.thumbnailView as? FKImageView, let image = imageView.image {
      return FKMediaGalleryLayoutMath.resolvedImageSize(from: image)
    }
    if source.thumbnailView?.bounds.width ?? 0 > 0 {
      return source.thumbnailView?.bounds.size ?? fallbackBounds.size
    }
    return fallbackBounds.size
  }
}

@MainActor
final class FKMediaGalleryTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
  var transition: FKMediaGalleryTransition = .crossDissolve
  var transitionSource: FKMediaGalleryTransitionSource?

  func animationController(
    forPresented presented: UIViewController,
    presenting: UIViewController,
    source: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    animator(isPresenting: true)
  }

  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    animator(isPresenting: false)
  }

  private func animator(isPresenting: Bool) -> UIViewControllerAnimatedTransitioning? {
    switch transition {
    case .system:
      return nil
    case .crossDissolve:
      return FKMediaGalleryTransitionAnimator(isPresenting: isPresenting, mode: .crossDissolve)
    case let .hero(options):
      if UIAccessibility.isReduceMotionEnabled {
        return FKMediaGalleryTransitionAnimator(isPresenting: isPresenting, mode: .crossDissolve)
      }
      return FKMediaGalleryTransitionAnimator(
        isPresenting: isPresenting,
        mode: .hero(options, transitionSource)
      )
    }
  }
}
