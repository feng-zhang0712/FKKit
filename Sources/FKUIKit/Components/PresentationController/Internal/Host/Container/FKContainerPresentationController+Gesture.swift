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
    let frameProvider: ((CGFloat) -> CGRect)?
    switch configuration.layout {
    case .bottomSheet(_):
      frameProvider = { [weak self] translationY in
        guard let self else { return .zero }
        return self.interactiveBottomSheetFrame(in: containerView, translationY: translationY)
      }
    case .topSheet(_):
      frameProvider = { [weak self] translationY in
        guard let self else { return .zero }
        return self.interactiveTopSheetFrame(in: containerView, translationY: translationY)
      }
    default:
      frameProvider = nil
    }
    guard let frameProvider else { return }

    recalculateDetentsIfNeeded()
    guard !resolvedDetentHeights.isEmpty else { return }

    let translation = recognizer.translation(in: containerView)
    let velocity = recognizer.velocity(in: containerView)
    let trackedScrollView = resolvedTrackedScrollView()

    switch recognizer.state {
    case .began:
      isPanningSheet = true
      panStartFrame = wrapperView.frame
      sheetPanBeganDetentIndex = selectedDetentIndex
      sheetPanVelocityY = 0
      if let trackedScrollView {
        trackedScrollView.panGestureRecognizer.isEnabled = true
      }

    case .changed:
      guard isPanningSheet else { return }
      sheetPanVelocityY = velocity.y

      if let trackedScrollView, !shouldTransferPanFromScrollView(trackedScrollView, translationY: translation.y) {
        // Let inner scroll own this direction while keeping sheet stable.
        animateToSelectedDetent(animated: false)
        return
      }

      let frame = frameProvider(translation.y)
      applyInteractiveFrame(frame)
      notifyProgress(sheetDismissProgress(in: containerView))
      updateBackdropForCurrentState()

    case .ended, .cancelled, .failed:
      guard isPanningSheet else { return }
      isPanningSheet = false

      if sheetShouldDismiss(translationY: translation.y, velocityY: velocity.y, in: containerView) {
        notifyProgress(1)
        keepsInteractiveFrameForDismissal = true
        dismissalStartingFrame = wrapperView.frame
        presentedViewController.dismiss(animated: true)
        sheetPanVelocityY = 0
        return
      }

      let targetIndex = nearestDetentIndex(for: wrapperView.frame, in: containerView, velocityY: velocity.y)
      selectDetentIndex(targetIndex, animated: true)
      notifyProgress(0)
      sheetPanVelocityY = 0

    default:
      break
    }
  }

  /// Same branch predicate as `interactiveBottomSheetFrame` / `interactiveTopSheetFrame` use for dismiss pull vs resize.
  func sheetDismissPullBranchActive(translationY: CGFloat, in containerView: UIView) -> Bool {
    let minHeight = resolvedDetentHeights.min() ?? 240
    let maxHeight = resolvedDetentHeights.max() ?? containerView.bounds.height * 0.9

    switch configuration.layout {
    case .bottomSheet(_):
      switch configuration.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        return sheetPanBeganDetentIndex == 0 && translationY > 0
      case .systemAligned:
        if sheetPanBeganDetentIndex == 0, translationY > 0 { return true }
        guard translationY > 0 else { return false }
        let translationToReachMinHeight = max(0, panStartFrame.height - minHeight)
        let extraDismissPull = translationY - translationToReachMinHeight
        guard extraDismissPull > 0 else { return false }
        let safeInsets = containerSafeInsets(in: containerView)
        let bottomExtra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
        let bottomY = containerView.bounds.height - bottomExtra
        let clampedH = min(max(panStartFrame.height - translationY, minHeight), maxHeight)
        let synthetic = CGRect(x: panStartFrame.minX, y: bottomY - clampedH, width: panStartFrame.width, height: clampedH)
        return nearestDetentIndex(for: synthetic, in: containerView, velocityY: 0) == 0
      }
    case .topSheet(_):
      switch configuration.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        return sheetPanBeganDetentIndex == 0 && translationY < 0
      case .systemAligned:
        guard translationY < 0 else { return false }
        let translationAtMin = minHeight - panStartFrame.height
        let extraDismissPull = translationAtMin - translationY
        guard extraDismissPull > 0 else { return false }
        let minY = sheetMinY(in: containerView)
        let clampedH = min(max(panStartFrame.height + translationY, minHeight), maxHeight)
        let synthetic = CGRect(x: panStartFrame.minX, y: minY, width: panStartFrame.width, height: clampedH)
        return nearestDetentIndex(for: synthetic, in: containerView, velocityY: 0) == 0
      }
    default:
      return false
    }
  }

  /// Extra translation along the dismiss axis after the sheet has reached min detent height (only meaningful when `sheetDismissPullBranchActive` is true).
  func sheetDismissExtraPullWhileInBranch(translationY: CGFloat) -> CGFloat {
    let minHeight = resolvedDetentHeights.min() ?? 240
    switch configuration.layout {
    case .bottomSheet(_):
      let translationToReachMinHeight = max(0, panStartFrame.height - minHeight)
      return max(0, translationY - translationToReachMinHeight)
    case .topSheet(_):
      let translationAtMin = minHeight - panStartFrame.height
      return max(0, translationAtMin - translationY)
    default:
      return 0
    }
  }

  func interactiveBottomSheetFrame(in containerView: UIView, translationY: CGFloat) -> CGRect {
    var frame = panStartFrame
    let safeInsets = containerSafeInsets(in: containerView)
    let bottomExtra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    let bottomY = containerView.bounds.height - bottomExtra
    let minHeight = resolvedDetentHeights.min() ?? 240
    let maxHeight = resolvedDetentHeights.max() ?? containerView.bounds.height * 0.9
    let dismissThreshold = configuration.sheet.dismissThreshold

    let inDismissPullBranch = sheetDismissPullBranchActive(translationY: translationY, in: containerView)

    if inDismissPullBranch {
      switch configuration.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        frame.origin.y = panStartFrame.origin.y + translationY
        frame.size.height = panStartFrame.size.height
      case .systemAligned:
        if sheetPanBeganDetentIndex == 0 {
          frame.origin.y = panStartFrame.origin.y + translationY
          frame.size.height = panStartFrame.size.height
        } else {
          let translationToReachMinHeight = max(0, panStartFrame.height - minHeight)
          let extraDismissPull = translationY - translationToReachMinHeight
          frame.size.height = minHeight
          frame.origin.y = (bottomY - minHeight) + extraDismissPull
        }
      }
    } else {
      // Upward drag expands, downward drag contracts toward the next smaller detent.
      frame.size.height = panStartFrame.height - translationY
      frame.size.height = min(max(frame.size.height, minHeight - dismissThreshold), maxHeight + dismissThreshold)
      frame.origin.y = bottomY - frame.size.height
    }

    let minY = sheetMinY(in: containerView)
    let maxY = sheetMaxY(in: containerView)
    if inDismissPullBranch {
      // At smallest detent, downward drag is dismiss / off-screen follow-through. Do not cap at
      // `maxY + dismissThreshold` (~44pt) or the sheet stops moving while the finger keeps going
      // (feels "stuck"), then often snaps back on release.
      frame.origin.y = max(frame.origin.y, minY - dismissThreshold)
    } else {
      frame.origin.y = min(max(frame.origin.y, minY - dismissThreshold), maxY + dismissThreshold)
    }
    return frame
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

  // MARK: - Top Sheet (mirror of bottom sheet, vertical axis inverted)

  func interactiveTopSheetFrame(in containerView: UIView, translationY: CGFloat) -> CGRect {
    var frame = panStartFrame
    let minY = sheetMinY(in: containerView)
    let minHeight = resolvedDetentHeights.min() ?? 240
    let maxHeight = resolvedDetentHeights.max() ?? containerView.bounds.height * 0.9
    let dismissThreshold = configuration.sheet.dismissThreshold

    let inDismissPullBranch = sheetDismissPullBranchActive(translationY: translationY, in: containerView)

    if inDismissPullBranch {
      switch configuration.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        frame.origin.y = panStartFrame.origin.y + translationY
        frame.size.height = panStartFrame.size.height
      case .systemAligned:
        let translationAtMin = minHeight - panStartFrame.height
        let extraDismissPull = translationAtMin - translationY
        frame.size.height = minHeight
        frame.origin.y = minY - extraDismissPull
      }
    } else {
      // Top sheet expands downward: finger down increases height; finger up decreases height.
      // The top edge must stay pinned at `minY` (unlike bottom sheets, there is no separate `maxY`
      // stop for the top edge—`sheetMaxY` collapses to `minY`). Reusing the bottom-sheet Y clamp
      // here is incorrect and can allow the shell to drift downward at large detents.
      frame.size.height = panStartFrame.height + translationY
      frame.size.height = min(max(frame.size.height, minHeight - dismissThreshold), maxHeight + dismissThreshold)
      frame.origin.y = minY
    }

    if inDismissPullBranch {
      // Do not cap upward dismiss travel to ~44pt; allow following the finger off-screen.
      frame.origin.y = min(frame.origin.y, minY)
    }

    return frame
  }

  // MARK: - Sheet Interaction Helpers

  func sheetMinY(in containerView: UIView) -> CGFloat {
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)
    if case .topSheet(_) = configuration.layout {
      return configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
    }
    let maxHeight = resolvedDetentHeights.max() ?? bounds.height * 0.5
    let extra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    return bounds.height - maxHeight - extra
  }

  func sheetMaxY(in containerView: UIView) -> CGFloat {
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)
    if case .topSheet(_) = configuration.layout {
      return configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
    }
    let minHeight = resolvedDetentHeights.min() ?? 240
    let extra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    return bounds.height - minHeight - extra
  }

  func sheetDismissProgress(in containerView: UIView) -> CGFloat {
    let bounds = containerView.bounds
    if case .topSheet(_) = configuration.layout {
      let minY = sheetMinY(in: containerView)
      let progress = (minY - wrapperView.frame.minY) / max(1, bounds.height * 0.25)
      return min(max(progress, 0), 1)
    }
    let progress = (sheetMaxY(in: containerView) - wrapperView.frame.minY) / max(1, bounds.height * 0.25)
    return min(max(progress, 0), 1)
  }

  func sheetShouldDismiss(translationY: CGFloat, velocityY: CGFloat, in containerView: UIView) -> Bool {
    guard configuration.dismissBehavior.allowsSwipe else { return false }
    let threshold = configuration.sheet.dismissThreshold
    let velocityThreshold = configuration.sheet.dismissVelocityThreshold

    switch configuration.layout {
    case .bottomSheet(_):
      switch configuration.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        guard sheetPanBeganDetentIndex == 0 else { return false }
        if translationY > threshold { return true }
        if velocityY > velocityThreshold { return true }
        return false
      case .systemAligned:
        if sheetPanBeganDetentIndex == 0 {
          if translationY > threshold { return true }
          if velocityY > velocityThreshold { return true }
          return false
        }
        guard sheetDismissPullBranchActive(translationY: translationY, in: containerView) else { return false }
        let extra = sheetDismissExtraPullWhileInBranch(translationY: translationY)
        if extra > threshold { return true }
        if extra > threshold * 0.5, velocityY > velocityThreshold { return true }
        return false
      }
    case .topSheet(_):
      switch configuration.sheet.crossDetentSwipeDismissPolicy {
      case .strictSmallestDetentAtPanStart:
        guard sheetPanBeganDetentIndex == 0 else { return false }
        if translationY < -threshold { return true }
        if velocityY < -velocityThreshold { return true }
        return false
      case .systemAligned:
        if sheetPanBeganDetentIndex == 0 {
          if translationY < -threshold { return true }
          if velocityY < -velocityThreshold { return true }
          return false
        }
        guard sheetDismissPullBranchActive(translationY: translationY, in: containerView) else { return false }
        let extra = sheetDismissExtraPullWhileInBranch(translationY: translationY)
        if extra > threshold { return true }
        if extra > threshold * 0.5, velocityY < -velocityThreshold { return true }
        return false
      }
    default:
      break
    }
    return false
  }

  func nearestDetentIndex(for frame: CGRect, in containerView: UIView, velocityY: CGFloat) -> Int {
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)
    let extra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? (safeInsets.top + safeInsets.bottom) : 0
    let availableHeight = bounds.height - extra

    let currentHeight: CGFloat
    switch configuration.layout {
    case .bottomSheet(_):
      let bottomExtra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
      currentHeight = bounds.height - frame.minY - bottomExtra
    case .topSheet(_):
      currentHeight = frame.height
    default:
      currentHeight = min(availableHeight, max(0, frame.height))
    }

    if abs(velocityY) > 900, resolvedDetentHeights.count >= 2 {
      switch configuration.layout {
      case .bottomSheet(_):
        return velocityY < 0 ? min(resolvedDetentHeights.count - 1, selectedDetentIndex + 1) : max(0, selectedDetentIndex - 1)
      case .topSheet(_):
        // Finger down (positive vy) expands toward larger detent; finger up shrinks.
        return velocityY > 0 ? min(resolvedDetentHeights.count - 1, selectedDetentIndex + 1) : max(0, selectedDetentIndex - 1)
      default:
        break
      }
    }

    if configuration.sheet.enablesMagneticSnapping {
      for (idx, h) in resolvedDetentHeights.enumerated() where abs(h - currentHeight) <= configuration.sheet.magneticSnapThreshold {
        return idx
      }
    }

    var best = 0
    var bestDistance = CGFloat.greatestFiniteMagnitude
    for (idx, h) in resolvedDetentHeights.enumerated() {
      let d = abs(h - currentHeight)
      if d < bestDistance {
        bestDistance = d
        best = idx
      }
    }
    return best
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

  func sheetOwnsDismissAxisPanFromScrollView(translationY: CGFloat, in containerView: UIView) -> Bool {
    switch configuration.layout {
    case .bottomSheet(_):
      guard translationY > 0 else { return false }
    case .topSheet(_):
      guard translationY < 0 else { return false }
    default:
      return false
    }

    switch configuration.sheet.crossDetentSwipeDismissPolicy {
    case .strictSmallestDetentAtPanStart:
      return sheetPanBeganDetentIndex == 0
    case .systemAligned:
      if sheetPanBeganDetentIndex == 0 { return true }
      if sheetDismissPullBranchActive(translationY: translationY, in: containerView) { return true }
      return nearestDetentIndex(for: wrapperView.frame, in: containerView, velocityY: 0) == 0
    }
  }

  func shouldTransferPanFromScrollView(_ scrollView: UIScrollView, translationY: CGFloat) -> Bool {
    if abs(translationY) < 0.5 { return true }
    guard let containerView else { return true }
    let atTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
    let maxOffsetY = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
    let atBottom = scrollView.contentOffset.y >= maxOffsetY - 0.5

    switch configuration.layout {
    case .bottomSheet(_):
      let canExpandToLargerDetent = selectedDetentIndex < max(0, resolvedDetentHeights.count - 1)
      if translationY < 0 {
        // Upward drag should prioritize detent expansion.
        return canExpandToLargerDetent || atTop
      }
      // Downward: at smallest detent this is dismiss/rubber-band — sheet must own the gesture.
      if sheetOwnsDismissAxisPanFromScrollView(translationY: translationY, in: containerView) {
        return true
      }
      // Larger detent: let inner scroll consume until scrolled to top, then sheet shrinks.
      return atTop
    case .topSheet(_):
      let canExpandToLargerDetent = selectedDetentIndex < max(0, resolvedDetentHeights.count - 1)
      if translationY > 0 {
        // Finger down expands top sheet toward larger detents.
        return canExpandToLargerDetent || atTop
      }
      // Finger up shrinks; at smallest detent it's dismiss / rubber-band — sheet owns it.
      if sheetOwnsDismissAxisPanFromScrollView(translationY: translationY, in: containerView) {
        return true
      }
      // Larger detent: let inner scroll consume until scrolled to bottom, then sheet shrinks.
      return atBottom
    default:
      return true
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
}

// MARK: - Gesture Delegate

@MainActor
extension FKContainerPresentationController {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === panToDismissGesture else { return true }
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let containerView else { return true }
    let velocity = pan.velocity(in: containerView)
    return abs(velocity.y) >= abs(velocity.x)
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    guard gestureRecognizer === panToDismissGesture || otherGestureRecognizer === panToDismissGesture else { return false }
    return otherGestureRecognizer.view is UIScrollView || gestureRecognizer.view is UIScrollView
  }
}
