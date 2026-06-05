import FKCoreKit
import UIKit

@MainActor
final class FKCalloutCenter {
  static let shared = FKCalloutCenter()

  /// Baseline merged into requests that do not override configuration; matches ``popoverDefault()``.
  var defaultConfiguration = FKCalloutConfiguration.popoverDefault()
  var tooltipConfiguration = FKCalloutConfiguration.tooltipDefault()
  var popoverConfiguration = FKCalloutConfiguration.popoverDefault()
  var menuConfiguration = FKCalloutConfiguration.menuDefault()

  private var presentations: [UUID: FKCalloutPresentation] = [:]
  private var dismissTasks: [UUID: Task<Void, Never>] = [:]
  private var keyboardHeight: CGFloat = 0

  var isPresenting: Bool { !presentations.isEmpty }

  private init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(relayoutIfNeeded),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(relayoutIfNeeded),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(sceneDidDisconnect(_:)),
      name: UIScene.didDisconnectNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillChange(_:)),
      name: UIResponder.keyboardWillChangeFrameNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func presentation(forAnchor anchor: UIView) -> FKCalloutPresentation? {
    presentations.values.first { $0.request.anchorView === anchor }
  }

  @discardableResult
  func show(builder: FKCalloutBuilder, id: UUID = UUID()) -> UUID? {
    guard let anchor = builder.anchorView else { return nil }
    guard presentationWindow(for: anchor) ?? topWindow() != nil else { return nil }

    if builder.configuration.presentationPolicy == .replaceActive {
      let existingIDs = Array(presentations.keys)
      for existingID in existingIDs {
        dismiss(id: existingID, reason: .replaced, animated: false)
      }
    }

    var configuration = builder.configuration
    if configuration.kind == .tooltip, configuration.autoDismissDuration == nil {
      configuration.autoDismissDuration = FKCalloutConfiguration.tooltipDefault().autoDismissDuration
    }

    let request = FKCalloutRequest(
      id: id,
      content: builder.content,
      configuration: configuration,
      hooks: builder.hooks,
      anchorView: anchor,
      sourceRect: builder.sourceRect,
      actionHandlers: builder.actionHandlers,
      menuSelectionHandler: builder.menuSelectionHandler,
      closeHandler: builder.closeHandler,
      customBeakViewProvider: builder.customBeakViewProvider
    )

    guard present(request: request) else { return nil }
    return id
  }

  func dismiss(id: UUID, reason: FKCalloutDismissReason = .manual, animated: Bool = true) {
    guard let presentation = presentations.removeValue(forKey: id) else { return }
    dismissPresentation(presentation, reason: reason, animated: animated)
  }

  func dismissActive(reason: FKCalloutDismissReason = .manual, animated: Bool = true) {
    let ids = Array(presentations.keys)
    for id in ids {
      dismiss(id: id, reason: reason, animated: animated)
    }
  }

  func update(id: UUID, content: FKCalloutContent, configuration: FKCalloutConfiguration? = nil) -> Bool {
    guard let presentation = presentations[id] else { return false }
    if let configuration {
      presentation.request.configuration = configuration
    }
    presentation.request.content = content
    presentation.overlayView.bubbleView.update(
      configuration: presentation.request.configuration,
      content: content,
      handlers: interactionHandlers(for: presentation.request, id: id),
      customBeakViewProvider: presentation.request.customBeakViewProvider
    )
    relayout(presentation: presentation)
    scheduleAutoDismissIfNeeded(for: presentation)
    return true
  }

  private func present(request: FKCalloutRequest) -> Bool {
    guard let anchor = request.anchorView,
          let window = presentationWindow(for: anchor) ?? topWindow()
    else { return false }

    let bubble = FKCalloutBubbleView(
      configuration: request.configuration,
      content: request.content,
      handlers: interactionHandlers(for: request, id: request.id),
      customBeakViewProvider: request.customBeakViewProvider
    )
    let overlay = FKCalloutOverlayView(bubbleView: bubble)
    overlay.frame = window.bounds
    overlay.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
    overlay.configureInteraction(
      tapOutsideToDismiss: request.configuration.tapOutsideToDismiss,
      passesThroughOutsideTouches: request.configuration.passesThroughOutsideTouches,
      hostWindow: window
    )
    overlay.onTapOutside = { [weak self] in
      self?.dismiss(id: request.id, reason: .tapOutside)
    }

    window.addSubview(overlay)

    let presentation = FKCalloutPresentation(
      id: request.id,
      request: request,
      overlayView: overlay,
      hostWindow: window
    )
    presentations[request.id] = presentation

    presentation.anchorObserver = FKCalloutAnchorObserver(
      anchorView: anchor,
      onRelayout: { [weak self, weak presentation] in
        guard let self, let presentation else { return }
        self.relayout(presentation: presentation)
      },
      onAnchorUnavailable: { [weak self, weak presentation] in
        guard let self, let presentation else { return }
        self.dismissPresentation(presentation, reason: .anchorUnavailable, animated: false)
      }
    )

    relayout(presentation: presentation)
    if case .customView = request.content {
      DispatchQueue.main.async { [weak self, weak presentation] in
        guard let self, let presentation else { return }
        self.relayout(presentation: presentation)
      }
    }
    request.hooks.willShow?(request.id)

    FKCalloutAnimator.animateIn(
      view: bubble,
      style: request.configuration.animationStyle,
      duration: request.configuration.animationDuration
    ) {
      request.hooks.didShow?(request.id)
      self.announceIfNeeded(request: request)
    }

    scheduleAutoDismissIfNeeded(for: presentation)
    return true
  }

  private func interactionHandlers(for request: FKCalloutRequest, id: UUID) -> FKCalloutInteractionHandlers {
    var handlers = FKCalloutInteractionHandlers()
    handlers.actionHandlers = Dictionary(uniqueKeysWithValues: request.actionHandlers.map { ($0.key, $0.value) })
    handlers.menuSelectionHandler = request.menuSelectionHandler
    handlers.closeHandler = request.closeHandler
    handlers.onDismissAfterInteraction = { [weak self] reason in
      self?.dismiss(id: id, reason: reason)
    }
    return handlers
  }

  private func relayout(presentation: FKCalloutPresentation) {
    guard let anchor = presentation.request.anchorView else {
      dismissPresentation(presentation, reason: .anchorUnavailable, animated: true)
      return
    }
    guard let window = presentation.hostWindow ?? anchor.window else {
      dismissPresentation(presentation, reason: .anchorUnavailable, animated: true)
      return
    }
    if anchor.isHidden || anchor.alpha < 0.01 {
      dismissPresentation(presentation, reason: .anchorUnavailable, animated: true)
      return
    }

    anchor.layoutIfNeeded()
    let source = presentation.request.sourceRect ?? anchor.bounds
    let anchorRect = anchor.convert(source, to: window)
    var configuration = presentation.request.configuration

    let layoutDirection = window.effectiveUserInterfaceLayoutDirection
    let layoutResult = computeLayout(
      anchorRect: anchorRect,
      configuration: configuration,
      content: presentation.request.content,
      layoutDirection: layoutDirection,
      window: window,
      bubbleView: presentation.overlayView.bubbleView
    )
    configuration = layoutResult.configuration

    presentation.request.configuration.placement = layoutResult.layout.placement
    presentation.overlayView.bubbleView.updateMetrics(
      beakCenterAlongEdge: layoutResult.layout.beakCenterAlongEdge,
      placement: layoutResult.layout.placement
    )
    presentation.overlayView.bubbleView.frame = layoutResult.layout.frame
    presentation.overlayView.bubbleView.setNeedsLayout()
    presentation.overlayView.bubbleView.layoutIfNeeded()

    let spotlightRect = configuration.backdrop.spotlightsAnchor
      ? presentation.overlayView.convert(anchorRect, from: window)
      : nil
    presentation.overlayView.updateBackdrop(
      style: configuration.backdrop,
      spotlightRectInOverlay: spotlightRect
    )
  }

  private struct LayoutComputationResult {
    var configuration: FKCalloutConfiguration
    var layout: FKCalloutLayoutEngine.Result
    var bubbleSize: CGSize
  }

  private func computeLayout(
    anchorRect: CGRect,
    configuration: FKCalloutConfiguration,
    content: FKCalloutContent,
    layoutDirection: UIUserInterfaceLayoutDirection,
    window: UIWindow,
    bubbleView: FKCalloutBubbleView
  ) -> LayoutComputationResult {
    var configuration = configuration
    let bottomObstruction = keyboardBottomObstruction(in: window, configuration: configuration)
    let layoutBounds = FKCalloutLayoutEngine.layoutBounds(
      containerBounds: window.bounds,
      safeAreaInsets: window.safeAreaInsets,
      screenEdgeMargin: configuration.screenEdgeMargin,
      bottomObstruction: bottomObstruction
    )
    let availableWidth = max(1, layoutBounds.width)
    let maxWidth = min(configuration.maxWidth, availableWidth)
    let resolvedMinWidth: CGFloat = {
      if configuration.matchesAnchorWidth {
        return min(availableWidth, max(anchorRect.width, configuration.minWidth ?? 0))
      }
      return configuration.minWidth ?? 0
    }()
    let customProvider: (@MainActor () -> UIView)? = {
      if case let .customView(provider) = content {
        return provider
      }
      return nil
    }()

    func measure(using placement: FKCalloutPlacement) -> CGSize {
      var sizingConfiguration = configuration
      sizingConfiguration.placement = placement
      return FKCalloutBubbleView.preferredSize(
        for: content,
        configuration: sizingConfiguration,
        maxWidth: maxWidth,
        minWidth: resolvedMinWidth,
        customViewProvider: customProvider,
        mountedCustomView: bubbleView.mountedCustomView
      )
    }

    func layout(using placement: FKCalloutPlacement, bubbleSize: CGSize) -> FKCalloutLayoutEngine.Result {
      FKCalloutLayoutEngine.layout(
        anchorRectInWindow: anchorRect,
        bubbleSize: bubbleSize,
        placement: placement,
        anchorSpacing: configuration.anchorSpacing,
        anchorAlignment: configuration.anchorAlignment,
        beakOffset: configuration.beakOffset,
        beakWidth: configuration.appearance.beakWidth,
        cornerRadius: configuration.appearance.cornerRadius,
        beakCornerInset: configuration.appearance.beakCornerInset,
        layoutDirection: layoutDirection,
        safeAreaInsets: window.safeAreaInsets,
        containerBounds: window.bounds,
        screenEdgeMargin: configuration.screenEdgeMargin,
        flipsWhenNeeded: configuration.flipsPlacementWhenNeeded,
        bottomObstruction: bottomObstruction
      )
    }

    var bubbleSize = measure(using: configuration.placement)
    var layoutResult = layout(using: configuration.placement, bubbleSize: bubbleSize)
    if layoutResult.placement != configuration.placement {
      configuration.placement = layoutResult.placement
      bubbleSize = measure(using: configuration.placement)
      layoutResult = layout(using: configuration.placement, bubbleSize: bubbleSize)
    }

    return LayoutComputationResult(configuration: configuration, layout: layoutResult, bubbleSize: bubbleSize)
  }

  private func keyboardBottomObstruction(in window: UIWindow, configuration: FKCalloutConfiguration) -> CGFloat {
    guard configuration.keyboardAvoidance == .relayout, keyboardHeight > 0 else { return 0 }
    return keyboardHeight
  }

  @objc private func keyboardWillChange(_ note: Notification) {
    guard let window = topWindow(),
          let frameValue = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
    else { return }

    let localFrame = window.convert(frameValue.cgRectValue, from: nil)
    let nextHeight = max(0, window.bounds.maxY - localFrame.minY)
    let willShow = nextHeight > 0
    keyboardHeight = nextHeight

    if willShow {
      let dismissIDs = presentations.filter { $0.value.request.configuration.keyboardAvoidance == .dismiss }.map(\.key)
      for id in dismissIDs {
        guard let presentation = presentations.removeValue(forKey: id) else { continue }
        dismissPresentation(presentation, reason: .manual, animated: true)
      }
    }

    relayoutIfNeeded()
  }

  @objc private func sceneDidDisconnect(_ note: Notification) {
    let ids = presentations.values
      .filter { $0.hostWindow?.windowScene === note.object as? UIWindowScene }
      .map(\.id)
    for id in ids {
      if let presentation = presentations.removeValue(forKey: id) {
        dismissPresentation(presentation, reason: .anchorUnavailable, animated: false)
      }
    }
  }

  @objc private func relayoutIfNeeded() {
    for presentation in presentations.values {
      relayout(presentation: presentation)
    }
  }

  private func dismissPresentation(
    _ presentation: FKCalloutPresentation,
    reason: FKCalloutDismissReason,
    animated: Bool
  ) {
    dismissTasks[presentation.id]?.cancel()
    dismissTasks[presentation.id] = nil

    presentation.anchorObserver?.invalidate()
    presentation.anchorObserver = nil
    presentation.request.hooks.willDismiss?(presentation.id, reason)

    let bubble = presentation.overlayView.bubbleView
    let overlay = presentation.overlayView
    let configuration = presentation.request.configuration
    let completion = {
      overlay.teardownInteraction()
      overlay.removeFromSuperview()
      presentation.request.hooks.didDismiss?(presentation.id, reason)
    }

    guard animated else {
      completion()
      return
    }

    FKCalloutAnimator.animateOut(
      view: bubble,
      style: configuration.animationStyle,
      duration: configuration.animationDuration,
      completion: completion
    )
  }

  private func scheduleAutoDismissIfNeeded(for presentation: FKCalloutPresentation) {
    dismissTasks[presentation.id]?.cancel()
    dismissTasks[presentation.id] = nil
    guard let duration = presentation.request.configuration.autoDismissDuration, duration > 0 else { return }
    let id = presentation.id
    dismissTasks[id] = Task { [weak self] in
      try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
      guard !Task.isCancelled else { return }
      await MainActor.run {
        self?.dismiss(id: id, reason: .timeout)
      }
    }
  }

  private func announceIfNeeded(request: FKCalloutRequest) {
    guard request.configuration.accessibilityAnnouncementEnabled else { return }
    let message: String? = {
      if let override = request.configuration.accessibilityAnnouncementOverride {
        return override
      }
      switch request.content {
      case let .message(text): return text
      case let .titleSubtitle(title, message): return "\(title). \(message)"
      case let .iconMessage(_, message): return message
      case let .messageWithActions(message, _): return message
      case let .headerPanel(header, body): return "\(header.title). \(body)"
      case let .coachMark(payload): return "\(payload.title). \(payload.message)"
      case .menu, .customView: return nil
      }
    }()
    guard let message, !message.isEmpty else { return }
    UIAccessibility.post(notification: .announcement, argument: message)
  }

  private func presentationWindow(for anchor: UIView) -> UIWindow? {
    if let window = anchor.window { return window }
    var ancestor: UIView? = anchor.superview
    while let view = ancestor {
      if let window = view.window { return window }
      ancestor = view.superview
    }
    if let hostWindow = anchor.fk_nearestViewController?.viewIfLoaded?.window {
      return hostWindow
    }
    return nil
  }

  private func topWindow() -> UIWindow? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.filter { $0.activationState == .foregroundActive }
    for scene in scenes {
      if let key = scene.windows.first(where: \.isKeyWindow) { return key }
      if let normal = scene.windows.first(where: { !$0.isHidden && $0.windowLevel == .normal }) { return normal }
    }
    return UIApplication.shared.fk_keyWindow
  }
}
