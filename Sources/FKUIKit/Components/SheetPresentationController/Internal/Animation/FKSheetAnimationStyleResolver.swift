import UIKit

/// Resolves mode-aware animation styles for FK sheet presentation transitions.
enum FKSheetAnimationStyleResolver {
  enum Family {
    case alertLikeCenter
    case sheetLike
  }

  enum InteractionState {
    case nonInteractive
    case interactive
  }

  struct TransitionStyle {
    let family: Family
    let duration: TimeInterval
    let timing: Timing
    let initialAlpha: CGFloat
    let finalAlpha: CGFloat
    let initialScale: CGFloat
    let finalScale: CGFloat
  }

  enum Timing {
    case spring(dampingRatio: CGFloat)
    case curve(UIView.AnimationCurve)
  }

  static func resolveTransitionStyle(
    layout: FKSheetPresentationConfiguration.Layout,
    animationConfiguration: FKSheetAnimationConfiguration,
    isPresentation: Bool,
    reduceMotionEnabled: Bool,
    interactionState: InteractionState
  ) -> TransitionStyle {
    if animationConfiguration.preset == .none {
      return .init(
        family: family(for: layout),
        duration: 0,
        timing: .curve(.linear),
        initialAlpha: 1,
        finalAlpha: 1,
        initialScale: 1,
        finalScale: 1
      )
    }

    let family = family(for: layout)

    if reduceMotionEnabled {
      let scale: CGFloat
      if family == .alertLikeCenter {
        scale = isPresentation ? 0.985 : 0.97
      } else {
        scale = 1
      }
      return .init(
        family: family,
        duration: min(0.2, max(0, animationConfiguration.duration)),
        timing: .curve(.easeInOut),
        initialAlpha: isPresentation ? 0 : 1,
        finalAlpha: isPresentation ? 1 : 0,
        initialScale: scale,
        finalScale: 1
      )
    }

    switch family {
    case .alertLikeCenter:
      return resolveAlertLikeCenterStyle(
        animationConfiguration: animationConfiguration,
        isPresentation: isPresentation,
        interactionState: interactionState
      )
    case .sheetLike:
      return resolveSheetLikeStyle(
        layout: layout,
        animationConfiguration: animationConfiguration,
        isPresentation: isPresentation,
        interactionState: interactionState
      )
    }
  }

  private static func resolveAlertLikeCenterStyle(
    animationConfiguration: FKSheetAnimationConfiguration,
    isPresentation: Bool,
    interactionState: InteractionState
  ) -> TransitionStyle {
    let initialScale: CGFloat = isPresentation ? 1.08 : 1
    let finalScale: CGFloat = isPresentation ? 1 : 0.92
    let initialAlpha: CGFloat = isPresentation ? 0 : 1
    let finalAlpha: CGFloat = isPresentation ? 1 : 0

    let duration: TimeInterval
    let timing: Timing

    switch animationConfiguration.preset {
    case .systemLike:
      if isPresentation {
        duration = 0.30
        timing = .spring(dampingRatio: 0.82)
      } else {
        duration = 0
        timing = .curve(.linear)
      }
    case .spring:
      duration = max(0.24, min(0.34, animationConfiguration.duration))
      timing = .spring(dampingRatio: min(max(animationConfiguration.dampingRatio, 0.78), 0.92))
    case .easeInOut:
      duration = max(0.2, min(0.32, animationConfiguration.duration))
      timing = .curve(.easeInOut)
    case .fade:
      duration = isPresentation ? 0.22 : 0.18
      timing = .curve(.linear)
    case .none:
      duration = 0
      timing = .curve(.linear)
    }

    let adjustedDuration = interactionState == .interactive && !isPresentation ? min(duration, 0.2) : duration

    return .init(
      family: .alertLikeCenter,
      duration: adjustedDuration,
      timing: timing,
      initialAlpha: initialAlpha,
      finalAlpha: finalAlpha,
      initialScale: initialScale,
      finalScale: finalScale
    )
  }

  private static func resolveSheetLikeStyle(
    layout: FKSheetPresentationConfiguration.Layout,
    animationConfiguration: FKSheetAnimationConfiguration,
    isPresentation: Bool,
    interactionState: InteractionState
  ) -> TransitionStyle {
    let duration: TimeInterval
    let timing: Timing

    switch animationConfiguration.preset {
    case .systemLike:
      if anchorLikeLayout(layout) {
        duration = isPresentation ? 0.26 : 0.20
        timing = .curve(.linear)
      } else {
        duration = isPresentation ? 0.42 : 0.32
        timing = .spring(dampingRatio: isPresentation ? 0.84 : 0.86)
      }
    case .spring:
      let clamped = max(0.3, min(0.42, animationConfiguration.duration))
      duration = isPresentation ? clamped : max(0.22, clamped * 0.82)
      if anchorLikeLayout(layout) {
        timing = .curve(.easeInOut)
      } else {
        timing = .spring(dampingRatio: min(max(animationConfiguration.dampingRatio, 0.8), 0.95))
      }
    case .easeInOut:
      let clamped = max(0.24, min(0.38, animationConfiguration.duration))
      duration = isPresentation ? clamped : max(0.22, clamped * 0.82)
      timing = .curve(.easeInOut)
    case .fade:
      duration = isPresentation ? 0.24 : 0.2
      timing = .curve(.linear)
    case .none:
      duration = 0
      timing = .curve(.linear)
    }

    let adjustedDuration = interactionState == .interactive && !isPresentation ? min(duration, 0.3) : duration
    return .init(
      family: .sheetLike,
      duration: adjustedDuration,
      timing: timing,
      initialAlpha: 1,
      finalAlpha: 1,
      initialScale: 1,
      finalScale: 1
    )
  }

  private static func anchorLikeLayout(_ layout: FKSheetPresentationConfiguration.Layout) -> Bool {
    switch layout {
    case .anchor:
      return true
    default:
      return false
    }
  }

  private static func family(for layout: FKSheetPresentationConfiguration.Layout) -> Family {
    if case .center(_) = layout { return .alertLikeCenter }
    return .sheetLike
  }
}
