import UIKit

@MainActor
extension FKContainerPresentationController {
  // MARK: - Gesture Installation

  /// Installs/removes outside-tap and pan gestures according to interaction policy.
  func installGesturesIfNeeded() {
    let allowsPassthrough: Bool = {
      if configuration.backgroundInteraction.isEnabled { return true }
      if case let .dim(_, alpha) = configuration.backdropStyle, alpha <= 0 {
        return configuration.zeroDimBackdropBehavior == .passthrough
      }
      return false
    }()
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
      handleSheetPan(recognizer, in: containerView)
    case .center(_):
      handleCenterPan(recognizer, in: containerView)
    default:
      break
    }
  }

  /// Tracks vertical drag progress for center layouts and decides finish/cancel.
  func handleCenterPan(_ recognizer: UIPanGestureRecognizer, in containerView: UIView) {
    guard configuration.center.dismissEnabled else { return }
    let translation = recognizer.translation(in: containerView)
    let progress = min(max(abs(translation.y) / max(1, containerView.bounds.height * 0.4), 0), 1)
    notifyProgress(progress)
    let velocityY = abs(recognizer.velocity(in: containerView).y)

    if recognizer.state == .ended || recognizer.state == .cancelled {
      if progress > configuration.center.dismissProgressThreshold || velocityY > configuration.center.dismissVelocityThreshold {
        presentedViewController.dismiss(animated: true)
      } else {
        notifyProgress(0)
      }
    }
  }

  /// Drives sheet detent interpolation and interactive dismiss transitions.
  func handleSheetPan(_ recognizer: UIPanGestureRecognizer, in containerView: UIView) {
    guard let environment = sheetInteractionEnvironment(in: containerView) else { return }

    recalculateDetentsIfNeeded()
    guard !resolvedDetentHeights.isEmpty else { return }

    let translation = recognizer.translation(in: containerView)
    let velocity = recognizer.velocity(in: containerView)
    let trackedScrollView = resolvedTrackedScrollView()

    switch recognizer.state {
    case .began:
      isPanningSheet = true
      sheetPanDeferredToScrollView = false
      sheetPanBypassesScrollHandoff = resolvesSheetPanBypassesScrollHandoff(
        recognizer: recognizer,
        trackedScrollView: trackedScrollView
      )
      panStartFrame = wrapperView.frame
      sheetPanBeganDetentIndex = selectedDetentIndex
      sheetPanVelocityY = 0
      trackedScrollView?.panGestureRecognizer.isEnabled = true

    case .changed:
      guard isPanningSheet else { return }
      sheetPanVelocityY = velocity.y
      var state = sheetInteractionState()

      if !sheetPanBypassesScrollHandoff,
         let trackedScrollView,
         !FKSheetPresentationInteractionEngine.shouldTransferPanFromScrollView(
          environment: environment,
          state: state,
          scrollView: trackedScrollView,
          translationY: translation.y
         ) {
        sheetPanDeferredToScrollView = true
        animateToSelectedDetent(animated: false)
        return
      }

      sheetPanDeferredToScrollView = false
      state = sheetInteractionState()
      let frame = FKSheetPresentationInteractionEngine.interactiveFrame(
        environment: environment,
        state: state,
        translationY: translation.y
      )
      applyInteractiveFrame(frame)
      state.wrapperFrame = wrapperView.frame
      notifyProgress(FKSheetPresentationInteractionEngine.sheetDismissProgress(environment: environment, state: state))
      updateBackdropForCurrentState()

    case .ended, .cancelled, .failed:
      guard isPanningSheet else { return }
      isPanningSheet = false

      if sheetPanDeferredToScrollView {
        sheetPanDeferredToScrollView = false
        sheetPanBypassesScrollHandoff = false
        sheetPanVelocityY = 0
        return
      }

      sheetPanBypassesScrollHandoff = false
      let state = sheetInteractionState()

      if FKSheetPresentationInteractionEngine.sheetShouldDismiss(
        environment: environment,
        state: state,
        translationY: translation.y,
        velocityY: velocity.y
      ) {
        notifyProgress(1)
        keepsInteractiveFrameForDismissal = true
        dismissalStartingFrame = wrapperView.frame
        presentedViewController.dismiss(animated: true)
        sheetPanVelocityY = 0
        return
      }

      let targetIndex = FKSheetPresentationInteractionEngine.nearestDetentIndex(
        environment: environment,
        state: state,
        frame: wrapperView.frame,
        velocityY: velocity.y
      )
      selectDetentIndex(targetIndex, animated: true)
      notifyProgress(0)
      sheetPanVelocityY = 0

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

  func applyInteractiveFrame(_ frame: CGRect) {
    // Interactive sizing assigns a fresh `frame`; reset any prior layer transform (e.g. keyboard
    // avoidance) before applying it so we do not compound translation with the new geometry.
    wrapperView.transform = .identity
    wrapperView.frame = frame
    layoutContentContainer()
    hostedPresentedView?.frame = contentContainerView.bounds
    applyContainerAppearance()
    if let containerView {
      applyKeyboardAvoidance(in: containerView)
    }
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

  func selectDetent(_ detent: FKPresentationDetent, animated: Bool) {
    guard let index = configuration.sheet.detents.firstIndex(where: { $0 == detent }) else { return }
    selectDetentIndex(index, animated: animated)
  }

  func animateToSelectedDetent(animated: Bool) {
    guard containerView != nil else { return }
    let targetFrame = frameOfPresentedViewInContainerView
    let distance = max(
      1,
      abs(wrapperView.frame.minY - targetFrame.minY),
      abs(wrapperView.frame.height - targetFrame.height)
    )
    let animations = {
      self.wrapperView.transform = .identity
      self.wrapperView.frame = targetFrame
      self.layoutContentContainer()
      self.hostedPresentedView?.frame = self.contentContainerView.bounds
      self.applyContainerAppearance()
      self.updateBackdropForCurrentState()
    }
    if animated {
      let velocityVector = CGVector(dx: 0, dy: sheetPanVelocityY / distance)
      let softenedVelocity = CGVector(dx: 0, dy: velocityVector.dy * 0.75)
      let timing = UISpringTimingParameters(dampingRatio: 0.86, initialVelocity: softenedVelocity)
      let animator = UIViewPropertyAnimator(duration: 0.42, timingParameters: timing)
      animator.addAnimations(animations)
      animator.startAnimation()
    } else {
      animations()
    }
  }

  func clampedContentHeight(_ height: CGFloat, containerView: UIView) -> CGFloat {
    var value = max(0, height)
    if let minimum = configuration.sheet.minimumContentHeight {
      value = max(value, minimum)
    }
    if let maximum = configuration.sheet.maximumContentHeight {
      value = min(value, maximum)
    }
    let safe = containerSafeInsets(in: containerView)
    let maxAvailable = containerView.bounds.height - safe.top - safe.bottom
    return min(value, maxAvailable)
  }

  func resolvesSheetPanBypassesScrollHandoff(
    recognizer: UIPanGestureRecognizer,
    trackedScrollView: UIScrollView?
  ) -> Bool {
    guard let trackedScrollView else { return true }
    let touchInWrapper = recognizer.location(in: wrapperView)
    let touchInScroll = recognizer.location(in: trackedScrollView)
    return FKSheetPresentationInteractionEngine.shouldBypassScrollHandoffForPan(
      touchLocationInWrapper: touchInWrapper,
      contentContainerFrame: contentContainerView.frame,
      scrollView: trackedScrollView,
      touchLocationInScrollView: touchInScroll
    )
  }
}

// MARK: - Gesture Delegate

@MainActor
extension FKContainerPresentationController {
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
