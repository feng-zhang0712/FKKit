import UIKit

@MainActor
extension FKOverlayPresentationViewController {
  func sheetInteractionEnvironment() -> FKSheetPresentationInteractionEnvironment? {
    FKSheetPresentationSheetInteractionContext.environment(
      configuration: configuration,
      containerBounds: view.bounds,
      presentationSafeInsets: containerSafeInsets()
    )
  }

  func sheetInteractionState() -> FKSheetPresentationInteractionState {
    FKSheetPresentationSheetInteractionContext.state(
      resolvedDetentHeights: resolvedDetentHeights,
      selectedDetentIndex: selectedDetentIndex,
      sheetPanBeganDetentIndex: sheetPanCoordinator.sheetPanBeganDetentIndex,
      panStartFrame: sheetPanCoordinator.panStartFrame,
      wrapperFrame: wrapperView.frame
    )
  }

  func resolvedTrackedScrollView() -> UIScrollView? {
    FKSheetScrollTracking.resolvedTrackedScrollView(
      strategy: configuration.sheet.scrollTrackingStrategy,
      in: children.first?.view
    )
  }

  func installGestures() {
    if !configuration.backgroundInteraction.isEnabled,
       configuration.dismissBehavior.allowsTapOutside,
       configuration.dismissBehavior.allowsBackdropTap {
      backdropView.isUserInteractionEnabled = true
      backdropView.addGestureRecognizer(tapToDismissGesture)
    } else {
      backdropView.isUserInteractionEnabled = false
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
    }
  }

  @objc func handleTapToDismiss(_ recognizer: UITapGestureRecognizer) {
    guard recognizer.state == .ended else { return }
    guard configuration.dismissBehavior.allowsTapOutside else { return }
    onRequestDismiss?()
  }

  @objc func handlePanToDismiss(_ recognizer: UIPanGestureRecognizer) {
    switch configuration.layout {
    case .bottomSheet(_), .topSheet(_):
      sheetPanCoordinator.handlePan(recognizer, in: view, actions: makeSheetPanActions())
    case .center(_):
      centerPanCoordinator.handlePan(recognizer, in: view, actions: makeCenterPanActions())
    default:
      break
    }
  }

  func makeSheetPanActions() -> FKSheetPresentationSheetPanCoordinator.Actions {
    FKSheetPresentationSheetPanCoordinator.Actions(
      recalculateDetents: { [weak self] in self?.recalculateDetentsIfNeeded() },
      resolvedDetentHeights: { [weak self] in self?.resolvedDetentHeights ?? [] },
      selectedDetentIndex: { [weak self] in self?.selectedDetentIndex ?? 0 },
      wrapperFrame: { [weak self] in self?.wrapperView.frame ?? .zero },
      setWrapperFrame: { [weak self] frame, settling in
        self?.applyOverlayInteractiveFrame(frame, appliesChrome: !settling)
      },
      environment: { [weak self] in self?.sheetInteractionEnvironment() },
      interactionState: { [weak self] in self?.sheetInteractionState() ?? .init(
        resolvedDetentHeights: [],
        selectedDetentIndex: 0,
        sheetPanBeganDetentIndex: 0,
        panStartFrame: .zero,
        wrapperFrame: .zero
      ) },
      trackedScrollView: { [weak self] in self?.resolvedTrackedScrollView() },
      bypassScrollHandoff: { [weak self] recognizer, scroll in
        guard let self else { return true }
        return FKSheetPresentationSheetInteractionContext.bypassesScrollHandoff(
          recognizer: recognizer,
          wrapperView: self.wrapperView,
          contentContainerFrame: self.contentContainerView.frame,
          trackedScrollView: scroll
        )
      },
      notifyProgress: { [weak self] progress in self?.onProgress?(progress) },
      animateToSelectedDetent: { [weak self] animated, settling in
        self?.animateToSelectedDetent(animated: animated, appliesChrome: !settling)
      },
      selectDetent: { [weak self] index, animated in self?.selectDetent(at: index, animated: animated) },
      dismiss: { [weak self] velocityY, _ in
        self?.performInteractiveDismiss(velocityY: velocityY)
      }
    )
  }

  func makeCenterPanActions() -> FKSheetPresentationCenterPanCoordinator.Actions {
    FKSheetPresentationCenterPanCoordinator.Actions(
      containerHeight: { [weak self] in self?.view.bounds.height ?? 0 },
      captureBaseBackdropAlpha: { [weak self] in self?.captureCenterDismissBaseBackdropAlpha() },
      applyInteractiveDismiss: { [weak self] translationY, progress in
        self?.applyCenterInteractiveDismissTransform(translationY: translationY, progress: progress)
      },
      resetInteractiveDismiss: { [weak self] animated in
        self?.resetCenterInteractiveDismissVisuals(animated: animated)
      },
      notifyProgress: { [weak self] progress in self?.onProgress?(progress) },
      dismiss: { [weak self] velocityY in
        self?.performInteractiveDismiss(velocityY: velocityY)
      },
      dismissProgressThreshold: { [weak self] in self?.configuration.center.dismissProgressThreshold ?? 0.5 },
      dismissVelocityThreshold: { [weak self] in self?.configuration.center.dismissVelocityThreshold ?? 900 }
    )
  }

  func applyOverlayInteractiveFrame(_ frame: CGRect, appliesChrome: Bool) {
    wrapperView.frame = frame
    layoutContent()
    if appliesChrome {
      applyAppearance()
    }
    updatePassthroughHitTesting()
  }

  func captureCenterDismissBaseBackdropAlpha() {
    switch configuration.backdropStyle {
    case let .dim(_, alpha):
      centerPanCoordinator.baseBackdropAlpha = alpha
    default:
      centerPanCoordinator.baseBackdropAlpha = 1
    }
  }

  func applyCenterInteractiveDismissTransform(translationY: CGFloat, progress: CGFloat) {
    wrapperView.transform = FKSheetPresentationInteractionSupport.centerDismissTransform(
      translationY: translationY,
      containerHeight: view.bounds.height
    )
  }

  func resetCenterInteractiveDismissVisuals(animated: Bool) {
    let updates = {
      self.wrapperView.transform = .identity
      switch self.configuration.backdropStyle {
      case let .dim(_, alpha):
        self.backdropView.setDimAlpha(alpha)
      default:
        self.backdropView.alpha = 1
      }
    }
    guard animated else {
      updates()
      return
    }
    let timing = UISpringTimingParameters(dampingRatio: 0.86, initialVelocity: .zero)
    let animator = UIViewPropertyAnimator(duration: 0.34, timingParameters: timing)
    animator.addAnimations(updates)
    animator.startAnimation()
  }
}

// MARK: UIGestureRecognizerDelegate

@MainActor
extension FKOverlayPresentationViewController {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === panToDismissGesture else { return true }
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = pan.velocity(in: view)
    guard abs(velocity.y) >= abs(velocity.x) else { return false }

    guard let trackedScrollView = resolvedTrackedScrollView(),
          let environment = sheetInteractionEnvironment() else { return true }

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
