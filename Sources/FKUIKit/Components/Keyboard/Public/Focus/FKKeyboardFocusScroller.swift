import UIKit

/// Scrolls a target view into the unobscured band when the keyboard appears or focus moves —
/// pins just above the keyboard by default (no forced pull-down when already at the top).
/// Opt out with ``FKKeyboardFocusConfiguration/alignsFocusedViewToKeyboard`` `false` for
/// minimum-only movement.
///
/// ## Comment / reply pattern
/// Prefer ``alignContentRect(_:toKeyboardUsing:additionalBottomInset:)`` with
/// `tableView.rectForRow(at:)` so alignment does not depend on a reusable cell instance.
/// That path always pins the row bottom to the keyboard/composer when reachable, and does
/// **not** expand top inset when the list is already at the top.
/// While an alignment rect is active, begin-editing notifications do **not** retarget scrolling
/// to the text field.
///
/// Prefer ``FKKeyboardAvoidanceController`` when the screen also needs keyboard bottom insets and
/// you only care about the first responder. Do not run this scroller and an avoidance controller
/// against the **same** scroll view — both own content insets. Pair with ``FKKeyboardLayout`` for
/// a bottom composer instead.
@MainActor
public final class FKKeyboardFocusScroller {
  /// Root view used to locate the first responder when ``focusedView`` is `nil` and no alignment rect is set.
  public weak var rootView: UIView?

  /// Scroll view that should reveal the target. When `nil`, a primary scroll view is discovered under ``rootView``.
  public weak var scrollView: UIScrollView?

  /// Explicit focus target for form-style scrolling. When `nil`, uses ``UIView/fk_findFirstResponder()``
  /// on ``rootView``. Ignored while an alignment content rect is active.
  public weak var focusedView: UIView?

  /// Sticky alignment view (legacy / convenience). Prefer ``alignContentRect(_:toKeyboardUsing:additionalBottomInset:)``.
  public weak var alignmentView: UIView?

  /// Focus configuration.
  public var configuration: FKKeyboardFocusConfiguration

  private let observer = FKKeyboardObserver()
  private let insetApplier = FKKeyboardScrollInsetApplier()
  private var isRunning = false
  private weak var lastInsetScrollView: UIScrollView?
  private let editingStorage = EditingTokenStorage()
  private var alignmentAdditionalBottomInset: CGFloat = 0
  /// Content-space rect for comment-cell alignment (`tableView.rectForRow`).
  private var alignmentRectInContent: CGRect?
  /// Deduplicates identical keyboard end frames (willChangeFrame often posts twice on show).
  private var lastHandledKeyboardEndFrame: CGRect = .null

  /// Creates a focus scroller.
  public init(
    rootView: UIView? = nil,
    scrollView: UIScrollView? = nil,
    configuration: FKKeyboardFocusConfiguration = .init()
  ) {
    self.rootView = rootView
    self.scrollView = scrollView
    self.configuration = configuration
    observer.postsHiddenInfoOnStop = true
    observer.onChange = { [weak self] info in
      self?.handleKeyboardInfo(info)
    }
  }

  deinit {
    let center = NotificationCenter.default
    editingStorage.tokens.forEach { center.removeObserver($0) }
    editingStorage.tokens.removeAll()
  }

  /// Starts automatic scrolling when the keyboard changes (if configured) and when editing begins.
  public func start() {
    isRunning = true
    if configuration.observesKeyboardAutomatically {
      observer.start()
    }
    startEditingObservationIfNeeded()
    if observer.current.isVisible {
      handleKeyboardInfo(observer.current)
    }
  }

  /// Stops the internal observer and begin-editing observation.
  public func stop() {
    isRunning = false
    observer.stop()
    FKKeyboardEditingObservation.remove(&editingStorage.tokens)
    clearAlignmentTarget(restoringInsets: true)
  }

  /// Scrolls using an external keyboard snapshot.
  public func handleKeyboardInfo(_ info: FKKeyboardInfo) {
    guard isRunning else { return }
    if !info.isVisible {
      lastHandledKeyboardEndFrame = .null
      insetApplier.restore(to: lastInsetScrollView)
      lastInsetScrollView = nil
      insetApplier.reset()
      return
    }
    guard shouldHandleKeyboardEndFrame(info.endFrameInScreen) else { return }

    let work = { [weak self] in
      guard let self else { return }
      if self.alignmentRectInContent != nil || self.alignmentView != nil {
        self.applyAlignment(using: info)
      } else {
        self.scrollFocusedViewVisible(using: info, focusedViewOverride: nil)
      }
    }
    runAlongsideKeyboard(info, work)
  }

  /// Scrolls the current focus target into view immediately (form-style; respects
  /// ``FKKeyboardFocusConfiguration/alignsFocusedViewToKeyboard``).
  public func scrollFocusedViewVisible(using info: FKKeyboardInfo? = nil) {
    let resolved = info ?? (observer.current.isVisible ? observer.current : nil)
    runAlongsideKeyboard(resolved) { [weak self] in
      self?.scrollFocusedViewVisible(using: resolved, focusedViewOverride: nil)
    }
  }

  /// Pins a **content-space** rect to the keyboard/composer (comment-cell pattern).
  ///
  /// Pass `tableView.rectForRow(at:)`. Always adjusts `contentOffset` so the row bottom meets the
  /// unobscured bottom when reachable (both upward and downward). Does **not** add extra top inset
  /// when the list cannot scroll further (already at the top).
  ///
  /// When the keyboard is not yet visible, only stores the rect; scrolling runs from the next
  /// keyboard frame update.
  public func alignContentRect(
    _ rect: CGRect,
    toKeyboardUsing info: FKKeyboardInfo? = nil,
    additionalBottomInset: CGFloat = 0
  ) {
    guard rect.height > 0.5, rect.width > 0.5 else { return }
    alignmentRectInContent = rect
    alignmentView = nil
    alignmentAdditionalBottomInset = max(0, additionalBottomInset)
    // New target: allow the next keyboard frame (or immediate apply) to run even if the frame
    // matches the previous show.
    lastHandledKeyboardEndFrame = .null

    let resolved = info ?? (observer.current.isVisible ? observer.current : nil)
    guard let resolved, resolved.isVisible else { return }
    _ = shouldHandleKeyboardEndFrame(resolved.endFrameInScreen)
    runAlongsideKeyboard(resolved) { [weak self] in
      self?.applyAlignment(using: resolved)
    }
  }

  /// Pins `view`’s bottom edge just above the keyboard and remembers it as ``alignmentView``.
  ///
  /// Prefer ``alignContentRect(_:toKeyboardUsing:additionalBottomInset:)`` for `UITableView` rows.
  public func alignBottom(
    of view: UIView,
    toKeyboardUsing info: FKKeyboardInfo? = nil,
    additionalBottomInset: CGFloat = 0
  ) {
    let hostScroll =
      scrollView
      ?? FKKeyboardScrollViewDiscovery.findPrimaryScrollView(in: rootView)
      ?? view.fk_enclosingScrollView()
    guard let hostScroll, view.isDescendant(of: hostScroll) else {
      alignmentView = view
      alignmentAdditionalBottomInset = max(0, additionalBottomInset)
      return
    }
    let rect = view.convert(view.bounds, to: hostScroll)
    alignContentRect(rect, toKeyboardUsing: info, additionalBottomInset: additionalBottomInset)
    alignmentView = view
  }

  /// Clears alignment state and optionally restores insets this scroller applied.
  public func clearAlignmentTarget(restoringInsets: Bool = true) {
    alignmentView = nil
    alignmentAdditionalBottomInset = 0
    alignmentRectInContent = nil
    lastHandledKeyboardEndFrame = .null
    guard restoringInsets else { return }
    insetApplier.restore(to: lastInsetScrollView)
    lastInsetScrollView = nil
    insetApplier.reset()
  }

  private var hasAlignmentTarget: Bool {
    alignmentRectInContent != nil || alignmentView != nil
  }

  private func shouldHandleKeyboardEndFrame(_ endFrame: CGRect) -> Bool {
    if lastHandledKeyboardEndFrame.width > 0,
      abs(lastHandledKeyboardEndFrame.minY - endFrame.minY) < 0.5,
      abs(lastHandledKeyboardEndFrame.height - endFrame.height) < 0.5
    {
      return false
    }
    lastHandledKeyboardEndFrame = endFrame
    return true
  }

  private func applyAlignment(using info: FKKeyboardInfo) {
    let scroll =
      scrollView
      ?? FKKeyboardScrollViewDiscovery.findPrimaryScrollView(in: rootView)
      ?? alignmentView?.fk_enclosingScrollView()
    guard let scroll else { return }

    if lastInsetScrollView !== scroll {
      insetApplier.restore(to: lastInsetScrollView)
      lastInsetScrollView = scroll
    }

    // Resolve content rect once; fall back to the view only if needed.
    var rect = alignmentRectInContent ?? .null
    if rect.height < 0.5, let view = alignmentView, view.isDescendant(of: scroll) {
      rect = view.convert(view.bounds, to: scroll)
      alignmentRectInContent = rect.height > 0.5 ? rect : nil
    }
    guard rect.height > 0.5 else { return }

    applyFocusAdjustment(
      rect: rect,
      in: scroll,
      info: info,
      additionalBottomInset: alignmentAdditionalBottomInset,
      placement: .alignContentToKeyboard,
      resetInsetsBeforeApply: true
    )
  }

  private func applyFocusAdjustment(
    rect rawRect: CGRect,
    in scroll: UIScrollView,
    info: FKKeyboardInfo?,
    additionalBottomInset: CGFloat,
    placement: FKKeyboardVisibleRectScrolling.Placement,
    resetInsetsBeforeApply: Bool
  ) {
    // Jump layout-guide to this keyboard snapshot so bounds match the end frame we align to.
    rootView?.layoutIfNeeded()

    var rect = rawRect
    let topPad = configuration.additionalTopInset
    rect.origin.y -= topPad
    rect.size.height += topPad

    let keyboardBottom = resolvedKeyboardBottomInset(
      info: info,
      in: scroll,
      additionalBottomInset: additionalBottomInset
    )
    let safeTopContribution = max(0, scroll.adjustedContentInset.top - scroll.contentInset.top)
    let safeBottomContribution: CGFloat =
      configuration.appliesKeyboardBottomInset
      ? max(0, scroll.adjustedContentInset.bottom - scroll.contentInset.bottom)
      : 0
    let baselineTop =
      (insetApplier.capturedContentTop ?? scroll.contentInset.top) + safeTopContribution
    // When the host layout-pins a composer (`appliesKeyboardBottomInset == false`), the pin
    // target is the scroll view’s bounds bottom (composer top). Load-more / other
    // `contentInset.bottom` must not be treated as keyboard-obscured height — that leaves a
    // permanent gap between the aligned row and the composer.
    let baselineBottom: CGFloat =
      configuration.appliesKeyboardBottomInset
      ? (insetApplier.capturedContentBottom ?? scroll.contentInset.bottom) + safeBottomContribution
      : 0

    let settled = FKKeyboardVisibleRectScrolling.adjustment(
      for: rect,
      in: scroll,
      baselineTopInset: baselineTop,
      baselineBottomInset: baselineBottom,
      keyboardBottomInset: keyboardBottom,
      distanceFromKeyboard: configuration.keyboardDistanceFromFocusedView,
      placement: placement
    )

    if resetInsetsBeforeApply, insetApplier.capturedContentTop != nil {
      insetApplier.restore(to: scroll)
    }
    lastInsetScrollView = scroll

    let bottomInset = configuration.appliesKeyboardBottomInset ? keyboardBottom : 0
    insetApplier.apply(
      bottomInset: bottomInset,
      extraTopInset: settled.extraTopInset,
      to: scroll
    )
    if abs(settled.contentOffsetY - scroll.contentOffset.y) > 0.5 {
      scroll.contentOffset = CGPoint(x: scroll.contentOffset.x, y: settled.contentOffsetY)
    }
  }

  private func scrollFocusedViewVisible(
    using info: FKKeyboardInfo?,
    focusedViewOverride: UIView?
  ) {
    let root = rootView
    let target = focusedViewOverride ?? focusedView ?? root?.fk_findFirstResponder()
    guard let target else { return }
    if let root, !target.isDescendant(of: root), focusedView == nil, focusedViewOverride == nil {
      return
    }

    let scroll =
      scrollView
      ?? FKKeyboardScrollViewDiscovery.findPrimaryScrollView(in: rootView)
      ?? target.fk_enclosingScrollView()
    guard let scroll, target.isDescendant(of: scroll) else { return }

    if lastInsetScrollView !== scroll {
      insetApplier.restore(to: lastInsetScrollView)
      lastInsetScrollView = scroll
    }

    let placement: FKKeyboardVisibleRectScrolling.Placement =
      configuration.alignsFocusedViewToKeyboard ? .alignContentToKeyboard : .minimumVisible

    var rect = target.convert(target.bounds, to: scroll)
    guard rect.height > 0.5 else { return }
    applyFocusAdjustment(
      rect: rect,
      in: scroll,
      info: info,
      additionalBottomInset: 0,
      placement: placement,
      resetInsetsBeforeApply: false
    )
  }

  private func runAlongsideKeyboard(_ info: FKKeyboardInfo?, _ work: @escaping () -> Void) {
    guard configuration.animatesAlongsideKeyboard else {
      work()
      return
    }
    if let info, info.isVisible {
      FKKeyboard.animate(alongside: info, animations: work)
    } else {
      UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState], animations: work)
    }
  }

  private func resolvedKeyboardBottomInset(
    info: FKKeyboardInfo?,
    in scroll: UIScrollView,
    additionalBottomInset: CGFloat
  ) -> CGFloat {
    let extra = max(0, additionalBottomInset)
    if let info, info.isVisible {
      return info.overlapHeight(
        in: scroll,
        subtractSafeAreaBottom: true,
        additionalBottomInset: extra
      )
    }
    if observer.current.isVisible {
      return observer.current.overlapHeight(
        in: scroll,
        subtractSafeAreaBottom: true,
        additionalBottomInset: extra
      )
    }
    return extra
  }

  private func startEditingObservationIfNeeded() {
    guard editingStorage.tokens.isEmpty else { return }
    editingStorage.tokens = FKKeyboardEditingObservation.addBeginEditingObservers { [weak self] view in
      MainActor.assumeIsolated {
        guard let self, self.isRunning else { return }
        if let root = self.rootView, !view.isDescendant(of: root) { return }
        if self.hasAlignmentTarget { return }
        let info = self.observer.current
        self.runAlongsideKeyboard(info.isVisible ? info : nil) {
          self.scrollFocusedViewVisible(
            using: info.isVisible ? info : nil,
            focusedViewOverride: view
          )
        }
      }
    }
  }
}

private final class EditingTokenStorage: @unchecked Sendable {
  var tokens: [NSObjectProtocol] = []
}

extension UIView {
  fileprivate func fk_enclosingScrollView() -> UIScrollView? {
    sequence(first: superview, next: { $0?.superview }).first { $0 is UIScrollView } as? UIScrollView
  }
}
