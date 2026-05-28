import UIKit

/// Presents and dismisses overlay-hosted sheets using the same style resolver as modal transitions.
@MainActor
enum FKSheetPresentationOverlayTransition {
  struct VisualState {
    var frame: CGRect
    var alpha: CGFloat
    var transform: CGAffineTransform
  }

  /// Animates overlay chrome for present/dismiss using ``FKAnimationStyleResolver``.
  static func animatePresentation(
    configuration: FKSheetPresentationConfiguration,
    isPresentation: Bool,
    animated: Bool,
    backdropView: UIView,
    wrapperView: UIView,
    baseFrame: CGRect,
    completion: @escaping () -> Void
  ) {
    let style = FKAnimationStyleResolver.resolveTransitionStyle(
      layout: configuration.layout,
      animationConfiguration: configuration.animation,
      isPresentation: isPresentation,
      reduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
      interactionState: .nonInteractive
    )

    let onScreen = onScreenVisualState(baseFrame: baseFrame, style: style)
    let offScreen = offScreenVisualState(
      baseFrame: baseFrame,
      style: style,
      layout: configuration.layout
    )
    let from = isPresentation ? offScreen : onScreen
    let to = isPresentation ? onScreen : offScreen

    apply(from, to: wrapperView, family: style.family)
    backdropView.alpha = isPresentation ? 0 : onScreen.alpha

    guard animated, style.duration > 0, configuration.animation.preset != .none else {
      apply(to, to: wrapperView, family: style.family)
      backdropView.alpha = isPresentation ? to.alpha : 0
      completion()
      return
    }

    let animator = makePropertyAnimator(style: style, animations: {
      apply(to, to: wrapperView, family: style.family)
      backdropView.alpha = isPresentation ? to.alpha : 0
    })
    animator.addCompletion { _ in completion() }
    animator.startAnimation()
  }

  /// Finishes an interactive sheet dismiss with velocity-informed motion before the host tears down.
  static func animateInteractiveDismiss(
    configuration: FKSheetPresentationConfiguration,
    backdropView: UIView,
    wrapperView: UIView,
    baseFrame: CGRect,
    dismissalVelocityY: CGFloat,
    completion: @escaping () -> Void
  ) {
    let style = FKAnimationStyleResolver.resolveTransitionStyle(
      layout: configuration.layout,
      animationConfiguration: configuration.animation,
      isPresentation: false,
      reduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
      interactionState: .interactive
    )
    let start = VisualState(
      frame: wrapperView.frame,
      alpha: wrapperView.alpha,
      transform: wrapperView.transform
    )
    let end = offScreenVisualState(
      baseFrame: baseFrame,
      style: style,
      layout: configuration.layout
    )

    guard style.duration > 0, configuration.animation.preset != .none else {
      apply(end, to: wrapperView, family: style.family)
      backdropView.alpha = 0
      completion()
      return
    }

    let travel = max(1, abs(start.frame.minY - end.frame.minY))
    let normalized = min(1.25, abs(dismissalVelocityY) / max(900, travel * 3.2))
    let duration = min(style.duration, max(0.18, style.duration * (1 - normalized * 0.35)))

    let animator: UIViewPropertyAnimator
    switch style.timing {
    case let .spring(dampingRatio):
      let params = UISpringTimingParameters(
        dampingRatio: dampingRatio,
        initialVelocity: CGVector(dx: 0, dy: normalized * 0.6)
      )
      animator = UIViewPropertyAnimator(duration: duration, timingParameters: params)
    case let .curve(curve):
      animator = UIViewPropertyAnimator(duration: duration, curve: curve)
    }

    animator.addAnimations {
      apply(end, to: wrapperView, family: style.family)
      backdropView.alpha = 0
    }
    animator.addCompletion { _ in completion() }
    animator.startAnimation()
  }

  // MARK: - Private

  private static func onScreenVisualState(
    baseFrame: CGRect,
    style: FKAnimationStyleResolver.TransitionStyle
  ) -> VisualState {
    VisualState(
      frame: baseFrame,
      alpha: style.finalAlpha,
      transform: CGAffineTransform(scaleX: style.finalScale, y: style.finalScale)
    )
  }

  private static func offScreenVisualState(
    baseFrame: CGRect,
    style: FKAnimationStyleResolver.TransitionStyle,
    layout: FKSheetPresentationConfiguration.Layout
  ) -> VisualState {
    let frame = style.family == .alertLikeCenter ? baseFrame : offsetFrame(for: baseFrame, layout: layout)
    return VisualState(
      frame: frame,
      alpha: style.initialAlpha,
      transform: CGAffineTransform(scaleX: style.initialScale, y: style.initialScale)
    )
  }

  private static func offsetFrame(
    for baseFrame: CGRect,
    layout: FKSheetPresentationConfiguration.Layout
  ) -> CGRect {
    switch layout {
    case .bottomSheet(_):
      return baseFrame.offsetBy(dx: 0, dy: baseFrame.height)
    case .topSheet(_):
      return baseFrame.offsetBy(dx: 0, dy: -baseFrame.height)
    case .center(_):
      return baseFrame
    case .anchor:
      return baseFrame.offsetBy(dx: 0, dy: 12)
    case let .edge(edge):
      if edge.contains(.left) { return baseFrame.offsetBy(dx: -baseFrame.width, dy: 0) }
      if edge.contains(.right) { return baseFrame.offsetBy(dx: baseFrame.width, dy: 0) }
      if edge.contains(.top) { return baseFrame.offsetBy(dx: 0, dy: -baseFrame.height) }
      return baseFrame.offsetBy(dx: 0, dy: baseFrame.height)
    }
  }

  private static func apply(
    _ state: VisualState,
    to wrapperView: UIView,
    family: FKAnimationStyleResolver.Family
  ) {
    wrapperView.alpha = state.alpha
    switch family {
    case .alertLikeCenter:
      wrapperView.bounds = CGRect(origin: .zero, size: state.frame.size)
      wrapperView.center = CGPoint(x: state.frame.midX, y: state.frame.midY)
      wrapperView.transform = state.transform
    case .sheetLike:
      wrapperView.transform = .identity
      wrapperView.frame = state.frame
    }
  }

  private static func makePropertyAnimator(
    style: FKAnimationStyleResolver.TransitionStyle,
    animations: @escaping () -> Void
  ) -> UIViewPropertyAnimator {
    switch style.timing {
    case let .spring(dampingRatio):
      let params = UISpringTimingParameters(dampingRatio: dampingRatio, initialVelocity: .zero)
      let animator = UIViewPropertyAnimator(duration: style.duration, timingParameters: params)
      animator.addAnimations(animations)
      return animator
    case let .curve(curve):
      return UIViewPropertyAnimator(duration: style.duration, curve: curve, animations: animations)
    }
  }
}
