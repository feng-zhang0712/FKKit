import UIKit

/// Animator that drives presentation and dismissal transitions based on `FKSheetPresentationConfiguration.Layout`.
final class FKSheetPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  private let isPresentation: Bool
  private let layout: FKSheetPresentationConfiguration.Layout
  private let animationConfiguration: FKSheetAnimationConfiguration
  private weak var interactiveDismiss: FKSheetPresentationInteractiveDismissTransition?
  private var cachedAnimator: UIViewImplicitlyAnimating?

  init(
    isPresentation: Bool,
    layout: FKSheetPresentationConfiguration.Layout,
    animationConfiguration: FKSheetAnimationConfiguration,
    interactiveDismiss: FKSheetPresentationInteractiveDismissTransition?
  ) {
    self.isPresentation = isPresentation
    self.layout = layout
    self.animationConfiguration = animationConfiguration
    self.interactiveDismiss = interactiveDismiss
    super.init()
  }

  func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
    let style = FKSheetAnimationStyleResolver.resolveTransitionStyle(
      layout: layout,
      animationConfiguration: animationConfiguration,
      isPresentation: isPresentation,
      reduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
      interactionState: .nonInteractive
    )
    return max(0, style.duration)
  }

  func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
    // Always go through the interruptible animator so interactive dismiss can drive progress smoothly.
    let animator = interruptibleAnimator(using: transitionContext)
    animator.startAnimation()
  }

  func interruptibleAnimator(using transitionContext: any UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
    if let cachedAnimator { return cachedAnimator }
    let key: UITransitionContextViewControllerKey = isPresentation ? .to : .from
    guard let controller = transitionContext.viewController(forKey: key) else {
      transitionContext.completeTransition(false)
      let fallback = UIViewPropertyAnimator(duration: 0, curve: .linear) {}
      cachedAnimator = fallback
      return fallback
    }

    let containerView = transitionContext.containerView
    let animatingView: UIView

    if isPresentation {
      guard let toView = transitionContext.view(forKey: .to) else {
        transitionContext.completeTransition(false)
        let fallback = UIViewPropertyAnimator(duration: 0, curve: .linear) {}
        cachedAnimator = fallback
        return fallback
      }
      containerView.addSubview(toView)
      animatingView = toView
    } else {
      guard let fromView = transitionContext.view(forKey: .from) else {
        transitionContext.completeTransition(false)
        let fallback = UIViewPropertyAnimator(duration: 0, curve: .linear) {}
        cachedAnimator = fallback
        return fallback
      }
      animatingView = fromView
    }

    // UIKit contract:
    // - Presentation: use `finalFrame(for: toVC)`
    // - Dismissal: use `initialFrame(for: fromVC)` as the baseline to compute exit frames
    let baseFrame = isPresentation
      ? transitionContext.finalFrame(for: controller)
      : transitionContext.initialFrame(for: controller)

    let style = FKSheetAnimationStyleResolver.resolveTransitionStyle(
      layout: layout,
      animationConfiguration: animationConfiguration,
      isPresentation: isPresentation,
      reduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
      interactionState: transitionContext.isInteractive ? .interactive : .nonInteractive
    )
    let start = initialState(for: baseFrame, style: style)
    let end = finalState(for: baseFrame, style: style)

    if isPresentation {
      apply(state: start, to: animatingView, family: style.family)
    }

    if animationConfiguration.preset == .none || style.duration == 0 {
      apply(state: isPresentation ? end : start, to: animatingView, family: style.family)
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
      let fallback = UIViewPropertyAnimator(duration: 0, curve: .linear) {}
      cachedAnimator = fallback
      return fallback
    }

    let context = FKSheetAnimationContext(
      isPresentation: isPresentation,
      layout: layout,
      animatingView: animatingView,
      startFrame: start.frame,
      endFrame: end.frame
    )

    let animator = makePropertyAnimator(
      style: style,
      context: context,
      animations: { [weak self] in
        guard let self else { return }
        if self.isPresentation {
          self.apply(state: end, to: animatingView, family: style.family)
        } else {
          self.apply(state: start, to: animatingView, family: style.family)
        }
      }
    )
    animator.addCompletion { position in
      // `transitionWasCancelled` is the source of truth for interactive cancellations. Using it keeps
      // host cleanup and callback order consistent between finish/cancel outcomes.
      let finished = (position == .end || position == .current) && !transitionContext.transitionWasCancelled
      transitionContext.completeTransition(finished)
      self.cachedAnimator = nil
      self.interactiveDismiss?.reset()
    }
    cachedAnimator = animator
    return animator
  }

  private struct State {
    var frame: CGRect
    var alpha: CGFloat
    var transform: CGAffineTransform
  }

  private func initialState(for baseFrame: CGRect, style: FKSheetAnimationStyleResolver.TransitionStyle) -> State {
    // Center keeps frame stable and communicates motion with subtle scale+alpha.
    // Sheet-like families start from an offset frame to preserve directional attachment cues.
    let frame = style.family == .alertLikeCenter ? baseFrame : initialFrame(for: baseFrame)
    return .init(
      frame: frame,
      alpha: style.initialAlpha,
      transform: CGAffineTransform(scaleX: style.initialScale, y: style.initialScale)
    )
  }

  private func finalState(for baseFrame: CGRect, style: FKSheetAnimationStyleResolver.TransitionStyle) -> State {
    return .init(
      frame: baseFrame,
      alpha: style.finalAlpha,
      transform: CGAffineTransform(scaleX: style.finalScale, y: style.finalScale)
    )
  }

  private func apply(state: State, to view: UIView, family: FKSheetAnimationStyleResolver.Family) {
    view.alpha = state.alpha
    switch family {
    case .alertLikeCenter:
      // Do not drive `frame` while `transform` carries scale: UIKit treats `frame` as undefined under
      // a non-identity `transform`, and layout passes that assign `frame` can desync chrome vs content.
      // `bounds` + fixed `center` keeps the card midpoint stable; scale uses the default anchorPoint
      // (0.5, 0.5), i.e. zoom in/out around the panel center — not the top-left.
      view.bounds = CGRect(origin: .zero, size: state.frame.size)
      view.center = CGPoint(x: state.frame.midX, y: state.frame.midY)
      view.transform = state.transform
    case .sheetLike:
      view.transform = .identity
      view.frame = state.frame
    }
  }

  private func initialFrame(for baseFrame: CGRect) -> CGRect {
    switch layout {
    case .bottomSheet(_):
      return baseFrame.offsetBy(dx: 0, dy: baseFrame.height)
    case .topSheet(_):
      return baseFrame.offsetBy(dx: 0, dy: -baseFrame.height)
    case .center(_):
      return baseFrame
    case let .anchor(configuration):
      // Anchor mode uses anchor-hosted hosting and follows anchor geometry for motion direction hints.
      return initialFrame(for: baseFrame, anchor: configuration.anchor)
    case let .edge(edge):
      if edge.contains(.left) { return baseFrame.offsetBy(dx: -baseFrame.width, dy: 0) }
      if edge.contains(.right) { return baseFrame.offsetBy(dx: baseFrame.width, dy: 0) }
      if edge.contains(.top) { return baseFrame.offsetBy(dx: 0, dy: -baseFrame.height) }
      return baseFrame.offsetBy(dx: 0, dy: baseFrame.height)
    }
  }

  private func initialFrame(for baseFrame: CGRect, anchor: FKAnchor) -> CGRect {
    let delta: CGFloat = 12
    switch anchor.direction {
    case .up:
      return baseFrame.offsetBy(dx: 0, dy: delta)
    case .down:
      return baseFrame.offsetBy(dx: 0, dy: -delta)
    case .auto:
      switch anchor.edge {
      case .top:
        return baseFrame.offsetBy(dx: 0, dy: -delta)
      case .bottom:
        return baseFrame.offsetBy(dx: 0, dy: delta)
      }
    }
  }

  private func makePropertyAnimator(
    style: FKSheetAnimationStyleResolver.TransitionStyle,
    context: FKSheetAnimationContext,
    animations: @escaping () -> Void
  ) -> UIViewPropertyAnimator {
    if let custom = animationConfiguration.customPropertyAnimator?(context) {
      custom.addAnimations(animations)
      return custom
    }

    switch style.timing {
    case let .spring(dampingRatio):
      let params = UISpringTimingParameters(
        dampingRatio: dampingRatio,
        initialVelocity: springInitialVelocity(for: context)
      )
      return UIViewPropertyAnimator(duration: style.duration, timingParameters: params).addingAnimations(animations)
    case let .curve(curve):
      if animationConfiguration.preset == .easeInOut, let timingCurve = animationConfiguration.timingCurve {
        return UIViewPropertyAnimator(duration: style.duration, timingParameters: timingCurve).addingAnimations(animations)
      }
      return UIViewPropertyAnimator(duration: style.duration, curve: curve, animations: animations)
    }
  }

  private func springInitialVelocity(for context: FKSheetAnimationContext) -> CGVector {
    if !isPresentation, let interactiveDismiss, interactiveDismiss.isArmed {
      return springInitialVelocityForInteractiveDismiss(context: context, dismissalVelocityY: interactiveDismiss.dismissalVelocityY)
    }

    switch layout {
    case .bottomSheet(_):
      let travel = max(1, abs(context.endFrame.minY - context.startFrame.minY))
      let normalized = min(1.0, travel / 520.0)
      if isPresentation {
        return CGVector(dx: 0, dy: -(0.28 + normalized * 0.16))
      }
      return CGVector(dx: 0, dy: 0.5 + normalized * 0.2)
    case .topSheet(_):
      return CGVector(dx: 0, dy: isPresentation ? -0.3 : 0.55)
    default:
      return .zero
    }
  }

  private func springInitialVelocityForInteractiveDismiss(context: FKSheetAnimationContext, dismissalVelocityY: CGFloat) -> CGVector {
    let travel = max(1, abs(context.endFrame.minY - context.startFrame.minY))
    let normalized = min(1.25, abs(dismissalVelocityY) / max(900, travel * 3.2))
    switch layout {
    case .bottomSheet(_):
      return CGVector(dx: 0, dy: 0.42 + normalized * 0.58)
    case .topSheet(_):
      return CGVector(dx: 0, dy: -(0.42 + normalized * 0.58))
    case .center(_):
      return CGVector(dx: 0, dy: dismissalVelocityY >= 0 ? 0.5 + normalized * 0.35 : -(0.5 + normalized * 0.35))
    default:
      return .zero
    }
  }
}

private extension UIViewPropertyAnimator {
  func addingAnimations(_ block: @escaping () -> Void) -> UIViewPropertyAnimator {
    addAnimations(block)
    return self
  }
}

