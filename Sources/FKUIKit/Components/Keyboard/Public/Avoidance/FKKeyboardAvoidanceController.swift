import UIKit

/// Applies keyboard avoidance to a host view using ``FKKeyboardAvoidanceStrategy``.
///
/// Opt-in: call ``start()`` after configuring the host (and optional scroll view). Prefer
/// ``FKKeyboardLayout`` Auto Layout pinning for new UIs when transform/inset mutation is unnecessary.
///
/// ## Strategy resolution
/// - ``FKKeyboardAvoidanceStrategy/adjustContentInsets`` — mutates scroll insets and, when
///   configured, pins the first responder just above the keyboard by default (no forced
///   pull-down at the top; opt out via ``FKKeyboardAvoidanceConfiguration/alignsFocusedViewToKeyboard``).
/// - ``FKKeyboardAvoidanceStrategy/adjustContainer`` / ``FKKeyboardAvoidanceStrategy/interactive`` —
///   translates a **non-scrolling** container just enough for the first responder (or container
///   bottom) to clear the keyboard.
/// - If those translate strategies are aimed at a ``UIScrollView`` (or only a scroll view is
///   available), the controller **falls back to content insets**. Transforming a full-screen
///   scroll view by its `frame.maxY` lifts the entire viewport by ~keyboard height and leaves a
///   large blank band — that is never correct for scrollable forms.
///
/// Keyboard overlap for insets is measured in the **scroll view’s** bounds (not the full host),
/// so screens that already pin a footer with ``FKKeyboardLayout`` do not get a double bottom inset.
@MainActor
public final class FKKeyboardAvoidanceController {
  /// Host view whose bounds define coordinate conversion for container translation.
  public weak var hostView: UIView?

  /// Optional non-scrolling container translated for ``FKKeyboardAvoidanceStrategy/adjustContainer`` /
  /// ``FKKeyboardAvoidanceStrategy/interactive``. Defaults to ``hostView`` when that view is not a scroll view.
  public weak var containerView: UIView?

  /// Explicit scroll view for content-inset avoidance. When `nil`, a primary scroll view is discovered under the host.
  public weak var scrollView: UIScrollView?

  /// Avoidance configuration.
  public var configuration: FKKeyboardAvoidanceConfiguration {
    didSet { apply(observer.current) }
  }

  /// Latest applied bottom inset (keyboard overlap used for layout), in points.
  public private(set) var appliedBottomInset: CGFloat = 0

  /// Vertical translation currently applied for container avoidance (negative moves up).
  public private(set) var appliedTranslationY: CGFloat = 0

  private let observer = FKKeyboardObserver()
  private let insetApplier = FKKeyboardScrollInsetApplier()
  private var isRunning = false
  private weak var lastInsetScrollView: UIScrollView?
  private weak var lastTranslatedView: UIView?
  private let editingStorage = AvoidanceEditingTokenStorage()

  private enum ResolvedMode {
    case none
    case contentInsets(UIScrollView)
    case translateContainer(UIView)
  }

  /// Creates a controller bound to a host view.
  public init(hostView: UIView, configuration: FKKeyboardAvoidanceConfiguration = .init()) {
    self.hostView = hostView
    self.configuration = configuration
    observer.postsHiddenInfoOnStop = true
    observer.onChange = { [weak self] info in
      self?.apply(info)
    }
  }

  deinit {
    let center = NotificationCenter.default
    editingStorage.tokens.forEach { center.removeObserver($0) }
    editingStorage.tokens.removeAll()
  }

  /// Starts observation (when configured) and applies the current keyboard state.
  public func start() {
    isRunning = true
    if configuration.observesKeyboardAutomatically {
      observer.start()
    }
    startEditingObservationIfNeeded()
    apply(observer.current)
  }

  /// Stops observation, restores scroll insets, and clears transforms.
  public func stop() {
    isRunning = false
    observer.stop()
    FKKeyboardEditingObservation.remove(&editingStorage.tokens)
    restoreInsetsAndTransform()
  }

  /// Feeds an external keyboard snapshot (use when ``FKKeyboardAvoidanceConfiguration/observesKeyboardAutomatically`` is `false`).
  public func handleKeyboardInfo(_ info: FKKeyboardInfo) {
    apply(info)
  }

  /// Transform representing the current container avoidance translation.
  public var avoidanceTransform: CGAffineTransform {
    CGAffineTransform(translationX: 0, y: appliedTranslationY)
  }

  private func apply(_ info: FKKeyboardInfo) {
    guard isRunning, let hostView else { return }
    guard configuration.strategy != .disabled else {
      restoreInsetsAndTransform()
      return
    }

    let mode = resolvedMode()
    let animations = {
      switch mode {
      case .none:
        self.restoreInsetsAndTransform()
      case .contentInsets(let scroll):
        self.applyContentInsets(to: scroll, info: info, focusedView: nil)
      case .translateContainer(let target):
        self.applyContainerTranslation(info: info, to: target, in: hostView)
      }
    }

    FKKeyboard.animate(alongside: info, animations: animations)
  }

  private func resolvedMode() -> ResolvedMode {
    switch configuration.strategy {
    case .disabled:
      return .none

    case .adjustContentInsets:
      if let scroll = resolvedScrollView() {
        return .contentInsets(scroll)
      }
      return .none

    case .adjustContainer, .interactive:
      if let container = containerView, !(container is UIScrollView) {
        return .translateContainer(container)
      }
      if let scroll = resolvedScrollView() {
        return .contentInsets(scroll)
      }
      if let host = hostView, !(host is UIScrollView) {
        return .translateContainer(host)
      }
      return .none
    }
  }

  private func resolvedScrollView() -> UIScrollView? {
    if let scrollView { return scrollView }
    if let container = containerView as? UIScrollView { return container }
    return FKKeyboardScrollViewDiscovery.findPrimaryScrollView(in: hostView)
  }

  /// Keyboard overlap inside the scroll view’s own bounds (avoids double-counting when a sibling
  /// footer is already pinned with ``FKKeyboardLayout``).
  private func keyboardOverlap(for scroll: UIScrollView, info: FKKeyboardInfo) -> CGFloat {
    info.overlapHeight(
      in: scroll,
      subtractSafeAreaBottom: configuration.subtractSafeAreaBottom,
      additionalBottomInset: configuration.additionalBottomInset
    )
  }

  private func applyContentInsets(
    to scroll: UIScrollView,
    info: FKKeyboardInfo,
    focusedView: UIView?
  ) {
    clearContainerTranslation()
    if lastInsetScrollView !== scroll {
      insetApplier.restore(to: lastInsetScrollView)
      lastInsetScrollView = scroll
    }

    // Keyboard dismissed: restore captured insets and repair contentOffset.
    guard info.isVisible else {
      insetApplier.restore(to: scroll)
      lastInsetScrollView = nil
      appliedBottomInset = 0
      return
    }

    let overlap = keyboardOverlap(for: scroll, info: info)
    appliedBottomInset = overlap

    let safeTopContribution = max(0, scroll.adjustedContentInset.top - scroll.contentInset.top)
    let safeBottomContribution = max(0, scroll.adjustedContentInset.bottom - scroll.contentInset.bottom)
    let baselineTop =
      (insetApplier.capturedContentTop ?? scroll.contentInset.top) + safeTopContribution
    let baselineBottom =
      (insetApplier.capturedContentBottom ?? scroll.contentInset.bottom) + safeBottomContribution

    if configuration.scrollsFocusedViewIntoVisibleArea,
      let focused = focusedView ?? hostView?.fk_findFirstResponder(),
      focused.isDescendant(of: scroll)
    {
      // Top padding only on the rect; keyboard gap is `keyboardDistanceFromFocusedView`
      // (do not bake the gap into `rect` or it is double-counted).
      let topPad = configuration.additionalTopInset
      var rect = focused.convert(focused.bounds, to: scroll)
      rect.origin.y -= topPad
      rect.size.height += topPad
      let placement: FKKeyboardVisibleRectScrolling.Placement =
        configuration.alignsFocusedViewToKeyboard ? .alignContentToKeyboard : .minimumVisible
      let planned = FKKeyboardVisibleRectScrolling.adjustment(
        for: rect,
        in: scroll,
        baselineTopInset: baselineTop,
        baselineBottomInset: baselineBottom,
        keyboardBottomInset: overlap,
        distanceFromKeyboard: configuration.keyboardDistanceFromFocusedView,
        placement: placement
      )
      insetApplier.apply(bottomInset: overlap, extraTopInset: planned.extraTopInset, to: scroll)
      scroll.layoutIfNeeded()
      // Recompute offset after insets settle (adjustedContentInset may include safe area).
      let settled = FKKeyboardVisibleRectScrolling.adjustment(
        for: rect,
        in: scroll,
        baselineTopInset: baselineTop,
        baselineBottomInset: baselineBottom,
        keyboardBottomInset: overlap,
        distanceFromKeyboard: configuration.keyboardDistanceFromFocusedView,
        placement: placement
      )
      FKKeyboardVisibleRectScrolling.applyOffset(settled, to: scroll)
    } else {
      insetApplier.apply(bottomInset: overlap, extraTopInset: 0, to: scroll)
    }
  }

  private func applyContainerTranslation(
    info: FKKeyboardInfo,
    to target: UIView,
    in hostView: UIView,
    focusedView: UIView? = nil
  ) {
    insetApplier.restore(to: lastInsetScrollView)
    lastInsetScrollView = nil
    insetApplier.reset()
    appliedBottomInset = 0

    if lastTranslatedView !== target {
      lastTranslatedView?.transform = .identity
      lastTranslatedView = target
    }

    let distance = max(
      configuration.keyboardDistanceFromFocusedView,
      configuration.additionalBottomInset
    )
    let keyboardTopY =
      info.isVisible
      ? info.keyboardTopY(in: hostView) - distance
      : hostView.bounds.maxY

    let currentTY = target.transform.ty
    let lift: CGFloat
    if let focused = focusedView ?? hostView.fk_findFirstResponder() {
      let focusedMaxY = focused.convert(focused.bounds, to: hostView).maxY - currentTY
      lift = max(0, focusedMaxY - keyboardTopY)
    } else {
      let targetMaxY =
        target.convert(CGPoint(x: 0, y: target.bounds.maxY), to: hostView).y - currentTY
      lift = max(0, targetMaxY - keyboardTopY)
    }

    appliedTranslationY = -lift
    target.transform = CGAffineTransform(translationX: 0, y: appliedTranslationY)
  }

  private func restoreInsetsAndTransform() {
    insetApplier.restore(to: lastInsetScrollView)
    lastInsetScrollView = nil
    insetApplier.reset()
    clearContainerTranslation()
    appliedBottomInset = 0
  }

  private func clearContainerTranslation() {
    if let target = lastTranslatedView ?? containerView ?? hostView, appliedTranslationY != 0 {
      target.transform = .identity
    }
    lastTranslatedView = nil
    appliedTranslationY = 0
  }

  private func handleBeginEditing(_ view: UIView) {
    guard isRunning else { return }
    guard configuration.scrollsFocusedViewIntoVisibleArea else { return }
    guard configuration.strategy != .disabled else { return }
    guard let host = hostView, view.isDescendant(of: host) else { return }
    let info = observer.current
    guard info.isVisible else { return }

    switch resolvedMode() {
    case .contentInsets(let scroll):
      let animations = {
        self.applyContentInsets(to: scroll, info: info, focusedView: view)
      }
      FKKeyboard.animate(alongside: info, animations: animations)

    case .translateContainer(let target):
      let animations = {
        self.applyContainerTranslation(info: info, to: target, in: host, focusedView: view)
      }
      FKKeyboard.animate(alongside: info, animations: animations)

    case .none:
      break
    }
  }

  private func startEditingObservationIfNeeded() {
    guard editingStorage.tokens.isEmpty else { return }
    editingStorage.tokens = FKKeyboardEditingObservation.addBeginEditingObservers { [weak self] view in
      MainActor.assumeIsolated {
        self?.handleBeginEditing(view)
      }
    }
  }
}

private final class AvoidanceEditingTokenStorage: @unchecked Sendable {
  var tokens: [NSObjectProtocol] = []
}
