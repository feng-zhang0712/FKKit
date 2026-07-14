import ObjectiveC
import UIKit

/// Entry point that wires content, configuration, and transition components together.
@MainActor
public final class FKSheetPresentationController: NSObject {
  public enum State: Equatable {
    case idle
    case presenting
    case presented
    case dismissing
  }

  /// Content controller that will be presented.
  ///
  /// For anchor layouts, this reference updates when you call
  /// ``presentOrReplaceAnchorContent(from:contentController:replacement:presentAnimated:completion:)`` or
  /// ``replaceAnchorContent(_:transition:animateLayout:layoutAnimationDuration:completion:)``.
  public private(set) var contentController: UIViewController
  /// Configuration describing the desired presentation behavior.
  public let configuration: FKSheetPresentationConfiguration
  /// Optional delegate receiving lifecycle updates.
  public weak var delegate: FKSheetPresentationControllerDelegate?
  /// Closure-based lifecycle handlers.
  public var handlers: FKSheetPresentationLifecycleHandlers
  /// Chooses whether lifecycle events are delivered through the delegate, handlers, or both.
  public var callbackDelivery: FKSheetPresentationCallbackDelivery
  /// Current controller state.
  public private(set) var state: State = .idle
  /// Whether content is currently visible.
  public var isPresented: Bool { state == .presented }
  /// Whether a transition is running.
  public var isTransitioning: Bool { state == .presenting || state == .dismissing }
  /// Currently selected detent when sheet modes are used (aligned with `UISheetPresentationController.selectedDetentIdentifier` semantics).
  public private(set) var selectedDetent: FKSheetPresentationDetent?
  /// Index of ``selectedDetent`` in ``detents``.
  public private(set) var selectedDetentIndex: Int?
  /// Detents the sheet may adopt (aligned with `UISheetPresentationController.detents`).
  public var detents: [FKSheetPresentationDetent] { configuration.sheet.detents }

  private var host: (any FKSheetPresentationHost)!

  /// Creates a presentation controller without presenting it immediately.
  public init(
    contentController: UIViewController,
    configuration: FKSheetPresentationConfiguration = .default,
    delegate: FKSheetPresentationControllerDelegate? = nil,
    handlers: FKSheetPresentationLifecycleHandlers = .init(),
    callbackDelivery: FKSheetPresentationCallbackDelivery = .handlersOnly
  ) {
    self.contentController = contentController
    self.configuration = configuration
    self.delegate = delegate
    self.handlers = handlers
    self.callbackDelivery = callbackDelivery
    super.init()

    // Host routing:
    // - `.anchor` stays inside the existing hierarchy because it must preserve local z-order,
    //   touch passthrough boundaries, and anchor attachment semantics that `UIPresentationController`
    //   cannot guarantee.
    // - Passthrough background interaction uses an in-hierarchy overlay host so touches outside the popup
    //   can reach the presenting UI.
    // - All other modes use UIKit custom modal presentation for system-like transitions and lifecycle.
    if case let .anchor(anchorConfig) = configuration.layout {
      self.host = FKAnchorHost(
        owner: self,
        contentController: contentController,
        configuration: configuration,
        anchorConfiguration: anchorConfig
      )
    } else {
      if configuration.requiresPassthroughOverlayHost {
        self.host = FKOverlayPresentationHost(owner: self, contentController: contentController, configuration: configuration)
      } else {
        self.host = FKModalPresentationHost(owner: self, contentController: contentController, configuration: configuration)
      }
    }
  }

  /// Presents content from a source view controller.
  public func present(from presentingViewController: UIViewController, animated: Bool = true, completion: (@MainActor () -> Void)? = nil) {
    guard assertMainThread("present", completion: completion) else { return }
    guard !isTransitioning else {
      completion?()
      return
    }
    guard !host.isPresented else {
      completion?()
      return
    }
    state = .presenting
    notifyWillPresent()
    host.present(from: presentingViewController, animated: animated) { [weak self] in
      self?.state = .presented
      self?.notifyDidPresent()
      completion?()
    }
  }

  /// Dismisses presented content if currently visible.
  public func dismiss(animated: Bool = true, completion: (@MainActor () -> Void)? = nil) {
    dismiss(animated: animated, notifiesLifecycle: true, completion: completion)
  }

  private func dismiss(
    animated: Bool,
    notifiesLifecycle: Bool,
    completion: (@MainActor () -> Void)?
  ) {
    guard assertMainThread("dismiss", completion: completion) else { return }
    guard !isTransitioning else {
      completion?()
      return
    }
    guard host.isPresented else {
      completion?()
      return
    }
    state = .dismissing
    if notifiesLifecycle {
      notifyWillDismiss()
    }
    host.dismiss(animated: animated) { [weak self] in
      guard let self else {
        completion?()
        return
      }
      self.state = .idle
      if notifiesLifecycle {
        self.notifyDidDismiss()
      }
      completion?()
    }
  }

  /// Re-applies host layout with optional animation.
  ///
  /// Supported on anchor, overlay passthrough, and modal hosts when content geometry changes outside
  /// `preferredContentSizeDidChange` (for example after async layout in a fit-content sheet).
  public func updateLayout(
    animated: Bool = false,
    duration: TimeInterval = 0.24,
    options: UIView.AnimationOptions = .curveEaseInOut
  ) {
    guard Thread.isMainThread else {
      assertionFailure("FKSheetPresentationController.updateLayout must be called on the main thread.")
      return
    }
    guard host.isPresented else { return }
    host.updateLayout(animated: animated, duration: duration, options: options)
  }

  /// Selects a detent when the active mode supports sheet detents.
  ///
  /// Supported for bottom/top sheet layouts on modal and overlay passthrough hosts.
  /// Anchor layout ignores detent APIs; edge and center layouts have no detents.
  public func selectDetent(_ detent: FKSheetPresentationDetent, animated: Bool = true) {
    guard assertMainThread("selectDetent") else { return }
    if let index = configuration.sheet.detents.firstIndex(of: detent) {
      selectDetent(at: index, animated: animated)
    }
  }

  /// Selects a detent by index when sheet modes are active.
  ///
  /// No-op when ``configuration/layout`` is `.anchor`, `.center`, or `.edge`.
  public func selectDetent(at index: Int, animated: Bool = true) {
    guard assertMainThread("selectDetent(at:)") else { return }
    switch configuration.layout {
    case .anchor, .center, .edge:
      assertionFailure("FKSheetPresentationController.selectDetent(at:) is not supported for the active layout.")
      return
    default:
      break
    }
    let clamped = max(0, min(index, max(0, configuration.sheet.detents.count - 1)))
    guard configuration.sheet.detents.indices.contains(clamped) else { return }
    if host is FKModalPresentationHost {
      (contentController.transitioningDelegate as? FKSheetPresentationTransitioningDelegate)?
        .activeContainerController?
        .selectDetent(configuration.sheet.detents[clamped], animated: animated)
    } else if let overlayHost = host as? FKOverlayPresentationHost {
      overlayHost.selectDetent(at: clamped, animated: animated)
    }
  }

  /// Convenience API for one-line presentation.
  @discardableResult
  public static func present(
    contentController: UIViewController,
    from presentingViewController: UIViewController,
    configuration: FKSheetPresentationConfiguration = .default,
    delegate: FKSheetPresentationControllerDelegate? = nil,
    handlers: FKSheetPresentationLifecycleHandlers = .init(),
    callbackDelivery: FKSheetPresentationCallbackDelivery = .handlersOnly,
    animated: Bool = true,
    completion: (@MainActor () -> Void)? = nil
  ) -> FKSheetPresentationController {
    let controller = FKSheetPresentationController(
      contentController: contentController,
      configuration: configuration,
      delegate: delegate,
      handlers: handlers,
      callbackDelivery: callbackDelivery
    )
    controller.present(from: presentingViewController, animated: animated, completion: completion)
    return controller
  }

  func notifyProgress(_ progress: CGFloat) {
    deliverCallbacks(
      delegate: { [weak self] in
        guard let self else { return }
        self.delegate?.presentationController(self, didUpdateProgress: progress)
      },
      handlers: { [weak self] in self?.handlers.progress?(progress) }
    )
  }

  func notifySelectedDetentDidChange(_ detent: FKSheetPresentationDetent, index: Int) {
    selectedDetent = detent
    selectedDetentIndex = index
    deliverCallbacks(
      delegate: { [weak self] in
        guard let self else { return }
        self.delegate?.presentationController(self, didChangeSelectedDetent: detent, at: index)
      },
      handlers: { [weak self] in self?.handlers.selectedDetentDidChange?(detent, index) }
    )
  }

  func notifyWillPresent() {
    deliverCallbacks(
      delegate: { [weak self] in
        guard let self else { return }
        self.delegate?.presentationControllerWillPresent(self)
      },
      handlers: { [weak self] in self?.handlers.willPresent?() }
    )
  }

  func notifyDidPresent() {
    deliverCallbacks(
      delegate: { [weak self] in
        guard let self else { return }
        self.delegate?.presentationControllerDidPresent(self)
      },
      handlers: { [weak self] in self?.handlers.didPresent?() }
    )
  }

  func notifyWillDismiss() {
    deliverCallbacks(
      delegate: { [weak self] in
        guard let self else { return }
        self.delegate?.presentationControllerWillDismiss(self)
      },
      handlers: { [weak self] in self?.handlers.willDismiss?() }
    )
  }

  func notifyDidDismiss() {
    deliverCallbacks(
      delegate: { [weak self] in
        guard let self else { return }
        self.delegate?.presentationControllerDidDismiss(self)
      },
      handlers: { [weak self] in self?.handlers.didDismiss?() }
    )
  }

  private func deliverCallbacks(
    delegate: () -> Void,
    handlers: () -> Void
  ) {
    switch callbackDelivery {
    case .delegateOnly:
      delegate()
    case .handlersOnly:
      handlers()
    case .both:
      delegate()
      handlers()
    }
  }

  private func assertMainThread(_ operation: String, completion: (@MainActor () -> Void)? = nil) -> Bool {
    guard Thread.isMainThread else {
      assertionFailure("FKSheetPresentationController.\(operation) must be called on the main thread.")
      completion?()
      return false
    }
    return true
  }

  private var isAnchorPresentation: Bool {
    if case .anchor = configuration.layout { return true }
    return false
  }

  private func bindContentController(_ contentController: UIViewController) {
    self.contentController = contentController
    (host as? FKAnchorHost)?.setContentController(contentController)
  }

  private func wireAnchorPreferredContentSizeRelay(
    for hostContainer: FKSheetPresentationAnchorContentHostViewController,
    animateLayout: Bool,
    duration: TimeInterval
  ) {
    hostContainer.onPreferredContentSizeDidChange = { [weak self] in
      guard let self else { return }
      self.updateLayout(
        animated: animateLayout,
        duration: animateLayout ? duration : 0,
        options: .curveEaseInOut
      )
    }
  }
}

// MARK: - Anchor replacement

public extension FKSheetPresentationController {
  /// Whether ``configuration/layout`` is anchor-hosted.
  var isAnchorHosted: Bool {
    if case .anchor = configuration.layout { return true }
    return false
  }

  /// Presents anchor content, or replaces it when this controller already owns a visible anchor popup.
  ///
  /// - Note: Calling ``present(from:animated:completion:)`` while already presented is a no-op. Use this API
  ///   when tapping the same anchor again with different content or height.
  func presentOrReplaceAnchorContent(
    from presentingViewController: UIViewController,
    contentController: UIViewController,
    replacement: FKSheetPresentationAnchorReplacementPolicy = .replaceInPlace(),
    presentAnimated: Bool = true,
    completion: (@MainActor () -> Void)? = nil
  ) {
    guard assertMainThread("presentOrReplaceAnchorContent", completion: completion) else { return }
    guard isAnchorPresentation, host is FKAnchorHost else {
      assertionFailure("presentOrReplaceAnchorContent requires anchor layout.")
      completion?()
      return
    }

    if !host.isPresented {
      bindContentController(contentController)
      present(from: presentingViewController, animated: presentAnimated, completion: completion)
      return
    }

    switch replacement {
    case let .dismissThenPresent(dismissAnimated, presentAnimated):
      bindContentController(contentController)
      dismiss(animated: dismissAnimated, notifiesLifecycle: false) { [weak self] in
        guard let self else {
          completion?()
          return
        }
        self.present(from: presentingViewController, animated: presentAnimated, completion: completion)
      }

    case let .replaceInPlace(contentTransition, animateLayout, layoutDuration):
      replaceAnchorContent(
        contentController,
        transition: contentTransition,
        animateLayout: animateLayout,
        layoutAnimationDuration: layoutDuration,
        completion: completion
      )
    }
  }

  /// Swaps anchor-hosted content while presented and relayouts the attached popup frame.
  ///
  /// When the presented root is a ``FKSheetPresentationAnchorContentHostViewController``, passing a child
  /// routes through ``FKSheetPresentationAnchorContentHostViewController/setContent(_:transition:completion:)``.
  func replaceAnchorContent(
    _ contentController: UIViewController,
    transition: FKSheetPresentationAnchorContentTransition = .crossfade(duration: 0.18),
    animateLayout: Bool = true,
    layoutAnimationDuration: TimeInterval = 0.24,
    completion: (@MainActor () -> Void)? = nil
  ) {
    guard assertMainThread("replaceAnchorContent", completion: completion) else { return }
    guard isAnchorPresentation, let anchorHost = host as? FKAnchorHost else {
      assertionFailure("replaceAnchorContent requires anchor layout.")
      completion?()
      return
    }

    if let hostContainer = self.contentController as? FKSheetPresentationAnchorContentHostViewController,
       contentController !== hostContainer,
       !(contentController is FKSheetPresentationAnchorContentHostViewController) {
      wireAnchorPreferredContentSizeRelay(for: hostContainer, animateLayout: animateLayout, duration: layoutAnimationDuration)
      hostContainer.setContent(contentController, transition: transition) { [weak anchorHost] in
        anchorHost?.updateLayout(
          animated: animateLayout,
          duration: animateLayout ? layoutAnimationDuration : 0,
          options: .curveEaseInOut
        )
        completion?()
      }
      return
    }

    bindContentController(contentController)

    guard host.isPresented else {
      completion?()
      return
    }

    anchorHost.replaceEmbeddedContent(
      transition: transition,
      animateLayout: animateLayout,
      layoutDuration: layoutAnimationDuration,
      completion: completion
    )
  }
}
