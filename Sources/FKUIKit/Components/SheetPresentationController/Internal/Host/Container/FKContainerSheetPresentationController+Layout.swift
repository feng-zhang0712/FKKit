import UIKit

@MainActor
extension FKContainerSheetPresentationController {
  // MARK: - Container Layout

  /// Applies corner radius, border and shadow on the wrapper shell.
  func applyContainerAppearance() {
    let radius = configuration.cornerRadius
    if let containerBlurView {
      containerBlurView.frame = wrapperView.bounds
      containerBlurView.maskedCornerRadius = radius
    }
    wrapperView.layer.cornerRadius = radius
    wrapperView.layer.masksToBounds = false
    let shadowPath = UIBezierPath(roundedRect: wrapperView.bounds, cornerRadius: radius).cgPath
    wrapperView.layer.fk_applyShadow(configuration.shadow, path: shadowPath)
    wrapperView.layer.fk_applyBorder(configuration.border)
    // `wrapperView` cannot clip (shadow). Match `FKAnchorHostViewController`’s `cardView` pattern so
    // opaque presented content does not paint over the rounded chrome when it fills the wrapper.
    contentContainerView.layer.cornerRadius = radius
  }

  /// Resolves container safe-area participation from selected policy.
  func containerSafeInsets(in containerView: UIView) -> UIEdgeInsets {
    FKSheetPresentationLayoutEngine.presentationSafeInsets(
      configuration: configuration,
      containerSafeAreaInsets: containerView.safeAreaInsets
    )
  }

  /// Lays out content container including safe-area and grabber offsets.
  func layoutContentContainer() {
    guard let containerView else {
      contentContainerView.frame = wrapperView.bounds
      return
    }

    if configuration.safeAreaPolicy == .contentRespectsSafeArea {
      let safe = containerView.safeAreaInsets
      let insets: UIEdgeInsets = {
        switch configuration.layout {
        case .bottomSheet(_):
          return .init(top: 0, left: 0, bottom: safe.bottom, right: 0)
        case .topSheet(_):
          return .init(top: safe.top, left: 0, bottom: 0, right: 0)
        case .center(_), .anchor:
          return safe
        case let .edge(edge):
          if edge.contains(.bottom) { return .init(top: 0, left: 0, bottom: safe.bottom, right: 0) }
          if edge.contains(.top) { return .init(top: safe.top, left: 0, bottom: 0, right: 0) }
          return safe
        }
      }()
      var frame = wrapperView.bounds.inset(by: insets)
      frame = frame.inset(by: grabberContentInsets())
      frame = frame.inset(by: UIEdgeInsets(configuration.contentInsets))
      contentContainerView.frame = frame
    } else {
      var frame = wrapperView.bounds
      frame = frame.inset(by: grabberContentInsets())
      frame = frame.inset(by: UIEdgeInsets(configuration.contentInsets))
      contentContainerView.frame = frame
    }

    layoutGrabber()
  }

  // MARK: - Grabber & Accessibility

  /// Computes extra content inset reserved for the grabber area.
  func grabberContentInsets() -> UIEdgeInsets {
    guard configuration.sheet.prefersGrabberVisible else { return .zero }
    let padding = configuration.sheet.grabberTopInset + configuration.sheet.grabberSize.height + 8
    switch configuration.layout {
    case .bottomSheet(_):
      return .init(top: padding, left: 0, bottom: 0, right: 0)
    case .topSheet(_):
      return .init(top: 0, left: 0, bottom: padding, right: 0)
    default:
      return .zero
    }
  }

  /// Adds/removes and styles grabber depending on active layout.
  func configureGrabberIfNeeded() {
    let prefersGrabberVisible: Bool
    switch configuration.layout {
    case .bottomSheet(_), .topSheet(_):
      prefersGrabberVisible = configuration.sheet.prefersGrabberVisible
    default:
      prefersGrabberVisible = false
    }

    if prefersGrabberVisible {
      if grabberView.superview == nil {
        wrapperView.addSubview(grabberView)
      }
      wrapperView.bringSubviewToFront(grabberView)
      grabberView.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.35)
      grabberView.layer.cornerRadius = configuration.sheet.grabberSize.height / 2
      grabberView.isHidden = false
    } else {
      grabberView.isHidden = true
      grabberView.removeFromSuperview()
    }
  }

  /// Configures accessibility labels/actions for backdrop and grabber affordances.
  func configureAccessibility() {
    backdropView.isAccessibilityElement = true
    backdropView.accessibilityTraits = [.button]
    backdropView.accessibilityLabel = configuration.accessibility.dismissLabel

    let dismissAction = UIAccessibilityCustomAction(name: configuration.accessibility.dismissActionName) { [weak self] _ in
      guard let self else { return false }
      self.presentedViewController.dismiss(animated: true)
      return true
    }
    backdropView.accessibilityCustomActions = [dismissAction]
    wrapperView.isAccessibilityElement = false

    if grabberView.superview != nil, !grabberView.isHidden {
      grabberView.isAccessibilityElement = true
      grabberView.accessibilityTraits = [.adjustable]
      grabberView.accessibilityLabel = configuration.accessibility.grabberLabel
      grabberView.accessibilityHint = configuration.accessibility.grabberHint
    }
  }

  /// Positions grabber near the interactive edge of the current layout.
  func layoutGrabber() {
    guard grabberView.superview != nil, !grabberView.isHidden else { return }
    let size = configuration.sheet.grabberSize
    let y: CGFloat = {
      if case .topSheet(_) = configuration.layout {
        return max(0, wrapperView.bounds.height - configuration.sheet.grabberTopInset - size.height)
      }
      return configuration.sheet.grabberTopInset
    }()
    grabberView.frame = CGRect(
      x: (wrapperView.bounds.width - size.width) / 2,
      y: y,
      width: size.width,
      height: size.height
    )
  }

  // MARK: - Detent Resolution

  func layoutEnvironment(in containerView: UIView) -> FKSheetPresentationLayoutEngine.Environment {
    FKSheetPresentationLayoutEngine.Environment(
      configuration: configuration,
      containerBounds: containerView.bounds,
      containerSafeAreaInsets: containerView.safeAreaInsets,
      preferredContentSize: presentedViewController.preferredContentSize,
      contentViewForFitting: hostedPresentedView
    )
  }

  func currentDetentState(in containerView: UIView) -> FKSheetPresentationLayoutEngine.DetentState {
    FKSheetPresentationLayoutEngine.DetentState(
      resolvedHeights: resolvedDetentHeights,
      selectedIndex: selectedDetentIndex
    )
  }

  /// Resolves current sheet height from active detent values.
  func resolvedSheetHeight(in containerView: UIView, bounds: CGRect, safeInsets: UIEdgeInsets) -> CGFloat {
    recalculateDetentsIfNeeded()
    let environment = layoutEnvironment(in: containerView)
    return FKSheetPresentationLayoutEngine.resolvedSheetHeight(
      environment: environment,
      detentState: currentDetentState(in: containerView)
    )
  }

  /// Recomputes all detent heights when geometry or content size changes.
  func recalculateDetentsIfNeeded() {
    guard let containerView else { return }
    let state = FKSheetPresentationLayoutEngine.recalculateDetents(
      environment: layoutEnvironment(in: containerView),
      selectedIndex: selectedDetentIndex
    )
    resolvedDetentHeights = state.resolvedHeights
    selectedDetentIndex = state.selectedIndex
  }

  /// Index of the smallest resolved detent height (independent of `detents` array order).
  func smallestDetentIndex() -> Int {
    FKSheetDetentIndexResolver.smallestIndex(in: resolvedDetentHeights)
  }

  /// Index of the largest resolved detent height (independent of `detents` array order).
  func largestDetentIndex() -> Int {
    FKSheetDetentIndexResolver.largestIndex(in: resolvedDetentHeights)
  }

  func clampedContentHeight(_ height: CGFloat, containerView: UIView) -> CGFloat {
    FKSheetPresentationLayoutEngine.clampedContentHeight(
      height,
      environment: layoutEnvironment(in: containerView)
    )
  }
}
