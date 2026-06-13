import ObjectiveC.runtime
import UIKit

// MARK: - UIView

public extension UIView {
  /// The overlay installed by `fk_applyEmptyState`; `nil` until the first presentation.
  var fk_emptyStateView: FKEmptyStateView? {
    objc_getAssociatedObject(self, &FKEmptyStateHostKeys.view) as? FKEmptyStateView
  }

  /// Last configuration stored for helpers such as `fk_refreshEmptyStateAutomatically` (`UIScrollView`); `nil` if never applied.
  var fk_emptyStateConfiguration: FKEmptyStateConfiguration? {
    (objc_getAssociatedObject(self, &FKEmptyStateHostKeys.configuration) as? FKEmptyStateConfigurationBox)?.configuration
  }

  /// `true` when an overlay was created and is currently presented (not hidden and not fully transparent).
  var fk_isEmptyStateOverlayVisible: Bool {
    guard let view = fk_emptyStateView else { return false }
    return !view.isHidden && view.alpha > 0.01
  }

  /// Updates content on an already-visible overlay without replaying the overlay fade-in.
  ///
  /// Falls back to ``fk_applyEmptyState(_:animated:actionHandler:viewTapHandler:)`` when no overlay is shown.
  func fk_updateVisibleEmptyState(
    _ configuration: FKEmptyStateConfiguration,
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    fk_emptyStateAssertMainThread()
    guard fk_isEmptyStateOverlayVisible, let view = fk_emptyStateView else {
      fk_applyEmptyState(
        configuration,
        animated: animated,
        actionHandler: actionHandler,
        viewTapHandler: viewTapHandler
      )
      return
    }

    objc_setAssociatedObject(
      self,
      &FKEmptyStateHostKeys.configuration,
      FKEmptyStateConfigurationBox(configuration),
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )

    if configuration.phase == .content {
      fk_hideEmptyState(animated: animated)
      return
    }

    if fk_emptyStateShouldSkipLoadingBecauseOfRefresh(host: self, configuration: configuration) {
      fk_hideEmptyState(animated: animated)
      return
    }

    view.actionHandler = actionHandler
    view.viewTapHandler = viewTapHandler
    let contentAnimated = animated && configuration.presentation.transition != .none
    view.apply(configuration, animated: contentAnimated)
    fk_emptyStateApplyScrollInteraction(host: self, configuration: configuration)
    bringSubviewToFront(view)
    if let scrollView = self as? UIScrollView {
      fk_emptyStateBringRefreshControlsToFront(on: scrollView)
    }
  }

  /// Applies or hides the empty-state overlay from `configuration`.
  ///
  /// - When `configuration.phase == .content`, hides the overlay (same as `fk_hideEmptyState`).
  /// - On `UIScrollView`, if `phase == .loading` and `presentation.loadingBehavior.skipsWhileRefreshing` is `true` while `refreshControl?.isRefreshing`, skips showing the loading overlay.
  /// - Creates the `FKEmptyStateView` once; subsequent calls update `isHidden` / `alpha` only.
  ///
  /// - Parameters:
  ///   - configuration: Visual and behavioral configuration.
  ///   - animated: Fade-in when the overlay is first shown; when already visible, drives ``FKEmptyStateView/apply(_:animated:)`` content transitions only.
  ///   - actionHandler: Invoked when an action button is tapped (primary/secondary/tertiary).
  ///     Use `action.id` to route multi-action flows and capture `[weak self]` to avoid retain cycles.
  ///   - viewTapHandler: Invoked when users tap the background area (outside any `UIControl`).
  @_disfavoredOverload
  func fk_applyEmptyState(
    _ configuration: FKEmptyStateConfiguration,
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    fk_emptyStateAssertMainThread()
    objc_setAssociatedObject(
      self,
      &FKEmptyStateHostKeys.configuration,
      FKEmptyStateConfigurationBox(configuration),
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )

    if configuration.phase == .content {
      fk_hideEmptyState(animated: animated)
      return
    }

    if fk_emptyStateShouldSkipLoadingBecauseOfRefresh(host: self, configuration: configuration) {
      if fk_emptyStateView != nil {
        fk_hideEmptyState(animated: animated)
      }
      return
    }

    let view = fk_ensureEmptyStateView()
    view.actionHandler = actionHandler
    view.viewTapHandler = viewTapHandler
    let overlayAlreadyVisible = fk_isEmptyStateOverlayVisible
    view.apply(configuration, animated: animated && overlayAlreadyVisible)

    let display = {
      view.isHidden = false
      view.alpha = 1
    }
    // Fade-in applies only when the overlay is newly presented. Re-applying while visible
    // should rely on `FKEmptyStateView.apply(_:animated:)` content transitions instead.
    let shouldAnimateOverlayPresentation = animated && !overlayAlreadyVisible && !UIAccessibility.isReduceMotionEnabled
    if shouldAnimateOverlayPresentation {
      view.alpha = 0
      view.isHidden = false
      UIView.animate(withDuration: configuration.presentation.fadeDuration, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: display)
    } else {
      display()
    }

    fk_emptyStateApplyScrollInteraction(host: self, configuration: configuration)
    bringSubviewToFront(view)
    if let scrollView = self as? UIScrollView {
      fk_emptyStateBringRefreshControlsToFront(on: scrollView)
    }
  }

  /// Applies or hides the empty-state overlay with `actionHandler` as the only trailing-closure parameter.
  ///
  /// This overload avoids Swift's deprecated "backward matching" when the caller uses
  /// `fk_applyEmptyState(config) { ... }`.
  ///
  /// - Important: Prefer this overload when you only care about action taps, as it avoids
  ///   ambiguity when there are multiple closure parameters.
  ///
  /// Minimal example:
  /// ```swift
  /// view.fk_applyEmptyState(config) { action in
  ///   if action.id == "retry" { reload() }
  /// }
  /// ```
  func fk_applyEmptyState(
    _ configuration: FKEmptyStateConfiguration,
    animated: Bool = true,
    actionHandler: @escaping (FKEmptyStateAction) -> Void
  ) {
    fk_applyEmptyState(
      configuration,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: nil
    )
  }

  /// Applies ``FKEmptyState/defaultConfiguration`` with a specific `phase` in one line.
  ///
  /// Use when you only need to toggle `loading` / `empty` / `error` / `content` quickly.
  ///
  /// - Note: A **copy** of ``FKEmptyState/defaultConfiguration`` is used so per-call changes do not mutate global defaults.
  func fk_setEmptyState(
    phase: FKEmptyStatePhase,
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    var config = FKEmptyState.defaultConfiguration
    config.phase = phase
    fk_applyEmptyState(
      config,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }

  /// Copies ``FKEmptyState/defaultConfiguration`` and lets you mutate a screen-local instance before applying.
  ///
  /// Preferred when you want shared chrome while customizing copy or actions per screen.
  func fk_setEmptyState(
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil,
    configure: (inout FKEmptyStateConfiguration) -> Void
  ) {
    var config = FKEmptyState.defaultConfiguration
    configure(&config)
    fk_applyEmptyState(
      config,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }

  /// Hides the empty-state overlay and restores `UIScrollView.isScrollEnabled` when the receiver is a scroll view.
  ///
  /// - Note: The overlay view stays in the hierarchy for reuse. Use ``fk_removeEmptyState(animated:)`` when the
  ///   host should not retain an empty-state subtree until the next presentation.
  func fk_hideEmptyState(animated: Bool = true) {
    fk_emptyStateAssertMainThread()
    guard let view = fk_emptyStateView else { return }
    let duration = fk_emptyStateConfiguration?.presentation.fadeDuration ?? 0.25
    let hideBlock = { view.alpha = 0 }
    let completion: (Bool) -> Void = { _ in
      view.isHidden = true
      if let scroll = self as? UIScrollView {
        scroll.isScrollEnabled = true
      }
    }
    let shouldAnimate = animated && !UIAccessibility.isReduceMotionEnabled
    if shouldAnimate {
      UIView.animate(withDuration: duration, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: hideBlock, completion: completion)
    } else {
      hideBlock()
      completion(true)
    }
  }

  /// Removes the empty-state overlay from the hierarchy and clears stored host state.
  ///
  /// Call when content is available and the overlay should not remain as a hidden subview.
  /// The next ``fk_applyEmptyState(_:animated:actionHandler:viewTapHandler:)`` recreates the overlay.
  func fk_removeEmptyState(animated: Bool = true) {
    fk_emptyStateAssertMainThread()
    guard let view = fk_emptyStateView else {
      fk_emptyStateClearHostStorage(on: self)
      return
    }
    view.layer.removeAllAnimations()
    let duration = fk_emptyStateConfiguration?.presentation.fadeDuration ?? 0.25
    let teardown = { [weak self] in
      guard let self else { return }
      view.removeFromSuperview()
      fk_emptyStateClearHostStorage(on: self)
      if let scroll = self as? UIScrollView {
        scroll.isScrollEnabled = true
      }
    }
    let shouldAnimate = animated && !UIAccessibility.isReduceMotionEnabled
    if shouldAnimate {
      UIView.animate(withDuration: duration, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
        view.alpha = 0
      }, completion: { _ in
        teardown()
      })
    } else {
      teardown()
    }
  }

  // MARK: Private

  /// Lazily creates `fk_emptyStateView`, pinned to `frameLayoutGuide` for `UIScrollView`, else to bounds.
  private func fk_ensureEmptyStateView() -> FKEmptyStateView {
    if let existing = fk_emptyStateView {
      return existing
    }
    let view = FKEmptyStateView()
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    if let scroll = self as? UIScrollView {
      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: scroll.frameLayoutGuide.topAnchor),
        view.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor),
        view.bottomAnchor.constraint(equalTo: scroll.frameLayoutGuide.bottomAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: topAnchor),
        view.leadingAnchor.constraint(equalTo: leadingAnchor),
        view.trailingAnchor.constraint(equalTo: trailingAnchor),
        view.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
    }
    objc_setAssociatedObject(self, &FKEmptyStateHostKeys.view, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return view
  }
}
