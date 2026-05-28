import UIKit

@MainActor
extension FKContainerSheetPresentationController {
  // MARK: - Gesture Installation

  /// Installs/removes outside-tap and pan gestures according to interaction policy.
  func installGesturesIfNeeded() {
    let allowsPassthrough = configuration.requiresPassthroughOverlayHost
    backdropView.isUserInteractionEnabled = !allowsPassthrough
    if allowsPassthrough, !configuration.backgroundInteraction.showsBackdropWhenEnabled {
      backdropView.isHidden = true
    } else {
      backdropView.isHidden = false
    }

    let allowsBackdropTapDismiss: Bool = {
      guard configuration.dismissBehavior.allowsTapOutside, configuration.dismissBehavior.allowsBackdropTap else { return false }
      if case let .dim(_, alpha) = configuration.backdropStyle, alpha <= 0 {
        return configuration.zeroDimBackdropBehavior == .dismissable
      }
      return true
    }()

    if !allowsPassthrough, allowsBackdropTapDismiss {
      backdropView.addGestureRecognizer(tapToDismissGesture)
    } else {
      backdropView.removeGestureRecognizer(tapToDismissGesture)
    }

    let allowsSwipe: Bool = {
      if case .center(_) = configuration.layout { return configuration.center.dismissEnabled }
      return configuration.dismissBehavior.allowsSwipe
    }()

    if allowsSwipe {
      panToDismissGesture.maximumNumberOfTouches = 1
      panToDismissGesture.delegate = self
      panToDismissGesture.cancelsTouchesInView = false
      wrapperView.addGestureRecognizer(panToDismissGesture)
    } else {
      panToDismissGesture.delegate = nil
      wrapperView.removeGestureRecognizer(panToDismissGesture)
    }
  }

  // MARK: - Gesture Handlers

  /// Handles backdrop taps for tap-outside dismissal.
  @objc func handleTapToDismiss(_ recognizer: UITapGestureRecognizer) {
    guard recognizer.state == .ended else { return }
    guard configuration.dismissBehavior.allowsTapOutside else { return }
    presentedViewController.dismiss(animated: true)
  }

  /// Routes pan gesture to center or sheet interaction handlers.
  @objc func handlePanToDismiss(_ recognizer: UIPanGestureRecognizer) {
    guard let containerView else { return }

    switch configuration.layout {
    case .bottomSheet(_), .topSheet(_):
      sheetPanCoordinator.handlePan(recognizer, in: containerView, actions: makeSheetPanActions(in: containerView))
    case .center(_):
      centerPanCoordinator.handlePan(recognizer, in: containerView, actions: makeCenterPanActions())
    default:
      break
    }
  }

  func interactiveBottomSheetFrame(in containerView: UIView, translationY: CGFloat) -> CGRect {
    guard let environment = sheetInteractionEnvironment(in: containerView) else { return .zero }
    return FKSheetPresentationInteractionEngine.interactiveFrame(
      environment: environment,
      state: sheetInteractionState(),
      translationY: translationY
    )
  }

  func interactiveTopSheetFrame(in containerView: UIView, translationY: CGFloat) -> CGRect {
    interactiveBottomSheetFrame(in: containerView, translationY: translationY)
  }

  func sheetDismissProgress(in containerView: UIView) -> CGFloat {
    guard let environment = sheetInteractionEnvironment(in: containerView) else { return 0 }
    return FKSheetPresentationInteractionEngine.sheetDismissProgress(
      environment: environment,
      state: sheetInteractionState()
    )
  }

  func sheetShouldDismiss(translationY: CGFloat, velocityY: CGFloat, in containerView: UIView) -> Bool {
    guard let environment = sheetInteractionEnvironment(in: containerView) else { return false }
    recalculateDetentsIfNeeded()
    return FKSheetPresentationInteractionEngine.sheetShouldDismiss(
      environment: environment,
      state: sheetInteractionState(),
      translationY: translationY,
      velocityY: velocityY
    )
  }

  func nearestDetentIndex(for frame: CGRect, in containerView: UIView, velocityY: CGFloat) -> Int {
    guard let environment = sheetInteractionEnvironment(in: containerView) else { return 0 }
    return FKSheetPresentationInteractionEngine.nearestDetentIndex(
      environment: environment,
      state: sheetInteractionState(),
      frame: frame,
      velocityY: velocityY
    )
  }

  func shouldTransferPanFromScrollView(_ scrollView: UIScrollView, translationY: CGFloat) -> Bool {
    guard let containerView, let environment = sheetInteractionEnvironment(in: containerView) else { return true }
    return FKSheetPresentationInteractionEngine.shouldTransferPanFromScrollView(
      environment: environment,
      state: sheetInteractionState(),
      scrollView: scrollView,
      translationY: translationY
    )
  }

  func selectDetentIndex(_ index: Int, animated: Bool) {
    let clamped = max(0, min(index, max(0, resolvedDetentHeights.count - 1)))
    if clamped == selectedDetentIndex { animateToSelectedDetent(animated: animated); return }
    selectedDetentIndex = clamped
    if configuration.sheet.detents.indices.contains(clamped) {
      notifySelectedDetentDidChange(configuration.sheet.detents[clamped], index: clamped)
      if configuration.haptics.isEnabled {
        let generator = UIImpactFeedbackGenerator(style: configuration.haptics.feedbackStyle)
        generator.impactOccurred()
      }
    }
    animateToSelectedDetent(animated: animated)
  }

  func selectDetent(_ detent: FKSheetPresentationDetent, animated: Bool) {
    guard let index = configuration.sheet.detents.firstIndex(where: { $0 == detent }) else { return }
    selectDetentIndex(index, animated: animated)
  }

  func animateToSelectedDetent(animated: Bool, layoutKind: FKInteractiveLayoutUpdateKind = .full) {
    guard containerView != nil else { return }
    let targetFrame = frameOfPresentedViewInContainerView
    let distance = max(
      1,
      abs(wrapperView.frame.minY - targetFrame.minY),
      abs(wrapperView.frame.height - targetFrame.height)
    )
    let animations = {
      self.applyInteractiveFrame(targetFrame, updateKind: layoutKind == .settling ? .settling : .full)
    }
    if animated {
      let duration = FKSheetPresentationInteractionSupport.adaptiveDetentSnapDuration(
        distance: distance,
        velocityY: sheetPanCoordinator.sheetPanVelocityY
      )
      let timing = UISpringTimingParameters(
        dampingRatio: 0.86,
        initialVelocity: FKSheetPresentationInteractionSupport.normalizedDetentSnapVelocity(
          velocityY: sheetPanCoordinator.sheetPanVelocityY,
          distance: distance
        )
      )
      let animator = UIViewPropertyAnimator(duration: duration, timingParameters: timing)
      animator.addAnimations(animations)
      animator.startAnimation()
    } else {
      animations()
    }
  }
}

// MARK: - Gesture Delegate

@MainActor
extension FKContainerSheetPresentationController {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === panToDismissGesture else { return true }
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let containerView else { return true }
    let velocity = pan.velocity(in: containerView)
    guard abs(velocity.y) >= abs(velocity.x) else { return false }

    guard let trackedScrollView = resolvedTrackedScrollView(),
          let environment = sheetInteractionEnvironment(in: containerView) else { return true }

    let touchInWrapper = pan.location(in: wrapperView)
    if !contentContainerView.frame.contains(touchInWrapper) { return true }

    let location = pan.location(in: trackedScrollView)
    return FKSheetPresentationInteractionEngine.shouldSheetPanBegin(
      environment: environment,
      state: sheetInteractionState(),
      scrollView: trackedScrollView,
      touchLocationInScrollView: location,
      verticalVelocity: velocity.y
    )
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    guard gestureRecognizer === panToDismissGesture || otherGestureRecognizer === panToDismissGesture else { return false }
    return otherGestureRecognizer.view is UIScrollView || gestureRecognizer.view is UIScrollView
  }
}
