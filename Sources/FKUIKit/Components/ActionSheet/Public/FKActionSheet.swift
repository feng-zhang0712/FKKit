import UIKit

/// Presents HIG-style action sheets backed by ``FKPresentationController``.
@MainActor
public enum FKActionSheet {
  private static weak var activeHandle: FKActionSheetHandle?
  private static var activePresentIDs: Set<String> = []

  /// Whether an action sheet is currently presented.
  ///
  /// Reflects the most recently presented sheet via ``FKActionSheet/present(configuration:hostContext:animated:completion:)``.
  /// Use the returned ``FKActionSheetHandle/isPresented`` when you retain a handle.
  public static var isPresenting: Bool {
    activeHandle?.isPresented == true
  }

  /// Validates configuration before presentation.
  public static func validate(
    _ configuration: FKActionSheetConfiguration,
    hostContext: FKActionSheetPresentationHostContext = .init()
  ) throws {
    try FKActionSheetValidator.validate(configuration)
    guard resolvePresenter(hostContext: hostContext) != nil else {
      throw FKActionSheetValidationError.presenterNotFound
    }
  }

  /// Presents an action sheet using an explicit presenter.
  @discardableResult
  public static func present(
    configuration: FKActionSheetConfiguration,
    from presenter: UIViewController,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws -> FKActionSheetHandle {
    try present(
      configuration: configuration,
      hostContext: FKActionSheetPresentationHostContext(presenter: presenter),
      animated: animated,
      completion: completion
    )
  }

  /// Presents an action sheet by resolving a presenter from ``FKActionSheetPresentationHostContext``.
  @discardableResult
  public static func present(
    configuration: FKActionSheetConfiguration,
    hostContext: FKActionSheetPresentationHostContext = .init(),
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws -> FKActionSheetHandle {
    try validate(configuration, hostContext: hostContext)
    guard let presenter = resolvePresenter(hostContext: hostContext) else {
      throw FKActionSheetValidationError.presenterNotFound
    }
    return presentValidated(
      configuration: configuration,
      hostContext: hostContext,
      presenter: presenter,
      animated: animated,
      presentationCompletion: completion
    )
  }

  /// Presents at most one sheet per `id` until it is dismissed.
  @discardableResult
  public static func presentOnce(
    id: String,
    configuration: FKActionSheetConfiguration,
    from presenter: UIViewController,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws -> FKActionSheetHandle? {
    try presentOnce(
      id: id,
      configuration: configuration,
      hostContext: FKActionSheetPresentationHostContext(presenter: presenter),
      animated: animated,
      completion: completion
    )
  }

  /// Presents at most one sheet per `id` until it is dismissed.
  @discardableResult
  public static func presentOnce(
    id: String,
    configuration: FKActionSheetConfiguration,
    hostContext: FKActionSheetPresentationHostContext = .init(),
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws -> FKActionSheetHandle? {
    guard !id.isEmpty else {
      return try present(configuration: configuration, hostContext: hostContext, animated: animated, completion: completion)
    }
    guard !activePresentIDs.contains(id) else { return nil }

    var config = configuration
    let priorDidDismiss = config.hooks.didDismiss
    config.hooks.didDismiss = { reason in
      priorDidDismiss?(reason)
      activePresentIDs.remove(id)
    }
    let handle = try present(configuration: config, hostContext: hostContext, animated: animated, completion: completion)
    activePresentIDs.insert(id)
    return handle
  }

  /// Convenience API for a single action group plus optional cancel.
  @discardableResult
  public static func present(
    title: String? = nil,
    message: String? = nil,
    actions: [FKActionSheetAction],
    cancelAction: FKActionSheetAction? = nil,
    hostContext: FKActionSheetPresentationHostContext = .init(),
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws -> FKActionSheetHandle {
    let configuration = FKActionSheetConfiguration(
      header: (title == nil && message == nil) ? nil : .text(FKActionSheetHeader(title: title, message: message)),
      sections: [FKActionSheetSection(actions: actions)],
      cancelAction: cancelAction
    )
    return try present(configuration: configuration, hostContext: hostContext, animated: animated, completion: completion)
  }

  /// Dismisses the most recently presented action sheet, if any.
  ///
  /// Prefer dismissing a retained ``FKActionSheetHandle`` when you need instance-scoped control.
  public static func dismissActive(animated: Bool = true, completion: (() -> Void)? = nil) {
    activeHandle?.dismiss(reason: .programmatic, animated: animated, completion: completion)
  }

  private static func resolvePresenter(hostContext: FKActionSheetPresentationHostContext) -> UIViewController? {
    FKActionSheetPresenterResolver.resolvePresenter(from: hostContext)
  }

  @discardableResult
  private static func presentValidated(
    configuration: FKActionSheetConfiguration,
    hostContext: FKActionSheetPresentationHostContext,
    presenter: UIViewController,
    animated: Bool,
    presentationCompletion: (() -> Void)?
  ) -> FKActionSheetHandle {
    if let activeHandle, activeHandle.isPresented {
      activeHandle.dismiss(reason: .programmatic, animated: false)
    }

    let resolvedConfiguration = configuration.applyingSelectionState()

    let content = FKActionSheetContentViewController()
    content.loadViewIfNeeded()
    content.apply(configuration: resolvedConfiguration)

    let presentationConfiguration = FKActionSheetPresentationFactory.makePresentationConfiguration(
      sheetPresentation: configuration.presentation,
      transform: configuration.presentationTransform
    )

    let presentation = FKPresentationController(
      contentController: content,
      configuration: presentationConfiguration
    )

    let handle = FKActionSheetHandle(
      presentationController: presentation,
      contentController: content,
      configuration: resolvedConfiguration
    )

    let session = FKActionSheetSession(
      handle: handle,
      configuration: resolvedConfiguration,
      presentationController: presentation,
      hostContext: hostContext,
      presenter: presenter
    )
    session.onDidPresentExtra = {
      content.focusAccessibility()
      presentationCompletion?()
    }
    handle.session = session
    content.session = session
    activeHandle = handle

    content.onPreferredContentSizeChange = { [weak presentation] in
      presentation?.updateLayout(animated: false)
    }

    wireContentCallbacks(handle: handle, session: session)

    presentation.present(from: presenter, animated: animated, completion: nil)
    return handle
  }

  private static func wireContentCallbacks(
    handle: FKActionSheetHandle,
    session: FKActionSheetSession
  ) {
    handle.contentController.onActionSelected = { action, sectionID, isCancelGroup in
      guard action.isEnabled else { return }
      if case .custom(let row) = action.rowContent, !row.isSelectable { return }
      if case .standard = action.rowContent, action.isLoading { return }
      if action.isToggleRow { return }

      let configuration = session.configuration
      session.notifyDidSelect(action)
      if configuration.haptics.onActionSelection {
        session.haptics.playSelection()
      }

      let isCancel = isCancelGroup || action.style == .cancel
      let dismissReason: FKActionSheetDismissReason = isCancel ? .userCancel : .actionSelected

      if case .single = configuration.selection.mode, !isCancel {
        session.applySingleSelection(action: action, sectionID: sectionID)
        if configuration.selection.keepsSheetPresentedOnSelection {
          invokeHandler(for: action, timing: configuration.handlerTiming, handle: handle, shouldDismiss: false)
          return
        }
      }

      let shouldDismiss = isCancel
        || action.dismissesSheetWhenSelected
        ?? configuration.dismissesAfterActionSelection

      if shouldDismiss {
        handle.stageDismissReason(dismissReason)
        invokeHandler(
          for: action,
          timing: configuration.handlerTiming,
          handle: handle,
          shouldDismiss: true,
          dismissReason: dismissReason
        )
      } else {
        invokeHandler(for: action, timing: configuration.handlerTiming, handle: handle, shouldDismiss: false)
      }
    }

    handle.contentController.onToggleValueChanged = { action, isOn in
      guard action.isEnabled else { return }
      session.updateToggleValue(actionID: action.id, isOn: isOn)
      action.toggleValueChanged?(isOn)
    }
  }

  private static func invokeHandler(
    for action: FKActionSheetAction,
    timing: FKActionSheetHandlerTiming,
    handle: FKActionSheetHandle,
    shouldDismiss: Bool,
    dismissReason: FKActionSheetDismissReason = .actionSelected
  ) {
    let hasHandler = action.handler != nil || action.actionHandler != nil
    guard hasHandler else {
      if shouldDismiss {
        handle.dismiss(reason: dismissReason, animated: true)
      }
      return
    }

    switch (timing, shouldDismiss) {
    case (.beforeDismiss, true), (.beforeDismiss, false):
      action.invokeHandlers()
      if shouldDismiss {
        handle.dismiss(reason: dismissReason, animated: true)
      }
    case (.afterDismissAnimation, false):
      action.invokeHandlers()
    case (.afterDismissAnimation, true):
      handle.dismiss(reason: dismissReason, animated: true) {
        action.invokeHandlers()
      }
    }
  }
}
