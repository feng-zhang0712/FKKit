import UIKit

@MainActor
extension FKOverlayPresentationViewController {
  func layoutEnvironment() -> FKSheetPresentationLayoutEngine.Environment {
    FKSheetPresentationLayoutEngine.Environment(
      configuration: configuration,
      containerBounds: view.bounds,
      containerSafeAreaInsets: view.safeAreaInsets,
      preferredContentSize: children.first?.preferredContentSize ?? .zero,
      contentViewForFitting: children.first?.view
    )
  }

  func currentDetentState() -> FKSheetPresentationLayoutEngine.DetentState {
    FKSheetPresentationLayoutEngine.DetentState(
      resolvedHeights: resolvedDetentHeights,
      selectedIndex: selectedDetentIndex
    )
  }

  func frameOfWrapper() -> CGRect {
    recalculateDetentsIfNeeded()
    return FKSheetPresentationLayoutEngine.wrapperFrame(
      environment: layoutEnvironment(),
      detentState: currentDetentState()
    )
  }

  func layoutContent() {
    contentContainerView.frame = wrapperView.bounds.inset(by: UIEdgeInsets(configuration.contentInsets))
    hostedContentView?.frame = contentContainerView.bounds
  }

  func applyAppearance() {
    let radius = configuration.cornerRadius
    wrapperView.layer.cornerRadius = radius
    wrapperView.layer.masksToBounds = false
    let shadowPath = UIBezierPath(roundedRect: wrapperView.bounds, cornerRadius: radius).cgPath
    wrapperView.layer.fk_applyShadow(configuration.shadow, path: shadowPath)
    wrapperView.layer.fk_applyBorder(configuration.border)
    contentContainerView.layer.cornerRadius = radius
  }

  func updatePassthroughHitTesting() {
    rootView.interactiveRect = wrapperView.frame
  }

  func containerSafeInsets() -> UIEdgeInsets {
    FKSheetPresentationLayoutEngine.presentationSafeInsets(
      configuration: configuration,
      containerSafeAreaInsets: view.safeAreaInsets
    )
  }

  func recalculateDetentsIfNeeded() {
    let state = FKSheetPresentationLayoutEngine.recalculateDetents(
      environment: layoutEnvironment(),
      selectedIndex: selectedDetentIndex
    )
    resolvedDetentHeights = state.resolvedHeights
    selectedDetentIndex = state.selectedIndex
  }

  func selectDetent(_ detent: FKSheetPresentationDetent, animated: Bool) {
    guard let index = configuration.sheet.detents.firstIndex(of: detent) else { return }
    selectDetent(at: index, animated: animated)
  }

  func selectDetent(at index: Int, animated: Bool) {
    recalculateDetentsIfNeeded()
    let clamped = max(0, min(index, max(0, resolvedDetentHeights.count - 1)))
    if clamped == selectedDetentIndex {
      animateToSelectedDetent(animated: animated)
      return
    }
    selectedDetentIndex = clamped
    if configuration.sheet.detents.indices.contains(clamped) {
      onSelectedDetentDidChange?(configuration.sheet.detents[clamped], clamped)
      if configuration.haptics.isEnabled {
        UIImpactFeedbackGenerator(style: configuration.haptics.feedbackStyle).impactOccurred()
      }
    }
    animateToSelectedDetent(animated: animated)
  }

  func animateToSelectedDetent(animated: Bool, appliesChrome: Bool = true) {
    let targetFrame = frameOfWrapper()
    let distance = max(1, abs(wrapperView.frame.minY - targetFrame.minY), abs(wrapperView.frame.height - targetFrame.height))
    let apply = {
      self.wrapperView.frame = targetFrame
      self.layoutContent()
      if appliesChrome {
        self.applyAppearance()
      }
      self.updatePassthroughHitTesting()
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
      animator.addAnimations(apply)
      animator.startAnimation()
    } else {
      apply()
    }
  }
}
