import UIKit

enum FKActionSheetPopoverAnchor {
  case sourceView(UIView, sourceRect: CGRect?, permittedArrowDirections: UIPopoverArrowDirection)
  case barButtonItem(UIBarButtonItem, permittedArrowDirections: UIPopoverArrowDirection)
}

extension FKActionSheet {
  /// Presents using `configuration.presentation.style` (`.bottom` or `.centered`).
  public func present(
    from presenter: UIViewController,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws {
    try present(from: presenter, popoverAnchor: nil, animated: animated, completion: completion)
  }

  /// Presents as a popover anchored to `sourceView`.
  public func present(
    from presenter: UIViewController,
    anchoredTo sourceView: UIView,
    sourceRect: CGRect? = nil,
    permittedArrowDirections: UIPopoverArrowDirection = .any,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws {
    try present(
      from: presenter,
      popoverAnchor: .sourceView(sourceView, sourceRect: sourceRect, permittedArrowDirections: permittedArrowDirections),
      animated: animated,
      completion: completion
    )
  }

  /// Presents as a popover anchored to a bar button item.
  public func present(
    from presenter: UIViewController,
    anchoredTo barButtonItem: UIBarButtonItem,
    permittedArrowDirections: UIPopoverArrowDirection = .any,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws {
    try present(
      from: presenter,
      popoverAnchor: .barButtonItem(barButtonItem, permittedArrowDirections: permittedArrowDirections),
      animated: animated,
      completion: completion
    )
  }

  /// Presents by resolving the topmost view controller in `windowScene`.
  public func present(
    in windowScene: UIWindowScene,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) throws {
    guard let presenter = Self.topPresenter(in: windowScene) else {
      throw FKActionSheetValidationError.presenterNotFound
    }
    try present(from: presenter, animated: animated, completion: completion)
  }

  func present(
    from presenter: UIViewController,
    popoverAnchor: FKActionSheetPopoverAnchor?,
    animated: Bool,
    completion: (() -> Void)?
  ) throws {
    if isPresented {
      throw FKActionSheetValidationError.alreadyPresented
    }
    if configuration.presentation.style == .popover, popoverAnchor == nil {
      throw FKActionSheetValidationError.popoverAnchorRequired
    }

    loadViewIfNeeded()

    let session = FKActionSheetSession(actionSheet: self, configuration: configuration)
    session.onDidPresentExtra = { [weak self] in
      self?.focusAccessibility()
      completion?()
    }
    self.session = session

    onPanelLayoutChange = { [weak self] in
      self?.view.setNeedsLayout()
      self?.view.layoutIfNeeded()
    }

    wireContentCallbacks(session: session)

    if let popoverAnchor {
      try applyPopoverPresentation(popoverAnchor, presenter: presenter)
    }

    presenter.present(self, animated: animated, completion: nil)
  }

  private func applyPopoverPresentation(
    _ anchor: FKActionSheetPopoverAnchor,
    presenter: UIViewController
  ) throws {
    var config = configuration
    if config.presentation.style != .popover {
      config.presentation.style = .popover
      apply(configuration: config)
    }

    modalPresentationStyle = .popover
    guard let popover = popoverPresentationController else { return }

    switch anchor {
    case .sourceView(let sourceView, let sourceRect, let directions):
      popover.sourceView = sourceView
      popover.sourceRect = sourceRect ?? sourceView.bounds
      popover.permittedArrowDirections = directions
    case .barButtonItem(let item, let directions):
      popover.barButtonItem = item
      popover.permittedArrowDirections = directions
    }

    if let delegate = presenter as? UIPopoverPresentationControllerDelegate {
      popover.delegate = delegate
    }
  }

  private func wireContentCallbacks(session: FKActionSheetSession) {
    onActionSelected = { [weak self] action, _, isCancelGroup in
      guard let self else { return }
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
        session.applySingleSelection(action: action)
        if configuration.selection.keepsSheetPresentedOnSelection {
          Self.invokeHandler(
            for: action,
            timing: configuration.handlerTiming,
            actionSheet: self,
            shouldDismiss: false
          )
          return
        }
      }

      let shouldDismiss = isCancel
        || action.dismissesSheetWhenSelected
        ?? configuration.dismissesAfterActionSelection

      if shouldDismiss {
        self.stageDismissReason(dismissReason)
        Self.invokeHandler(
          for: action,
          timing: configuration.handlerTiming,
          actionSheet: self,
          shouldDismiss: true,
          dismissReason: dismissReason
        )
      } else {
        Self.invokeHandler(
          for: action,
          timing: configuration.handlerTiming,
          actionSheet: self,
          shouldDismiss: false
        )
      }
    }

    onToggleValueChanged = { action, isOn in
      guard action.isEnabled else { return }
      session.updateToggleValue(actionID: action.id, isOn: isOn)
      action.toggleValueChanged?(isOn)
    }
  }

  private static func invokeHandler(
    for action: FKActionSheetAction,
    timing: FKActionSheetHandlerTiming,
    actionSheet: FKActionSheet,
    shouldDismiss: Bool,
    dismissReason: FKActionSheetDismissReason = .actionSelected
  ) {
    guard action.actionHandler != nil else {
      if shouldDismiss {
        actionSheet.dismiss(reason: dismissReason, animated: true)
      }
      return
    }

    switch (timing, shouldDismiss) {
    case (.beforeDismiss, true), (.beforeDismiss, false):
      action.invokeHandlers()
      if shouldDismiss {
        actionSheet.dismiss(reason: dismissReason, animated: true)
      }
    case (.afterDismissAnimation, false):
      action.invokeHandlers()
    case (.afterDismissAnimation, true):
      actionSheet.dismiss(reason: dismissReason, animated: true) {
        action.invokeHandlers()
      }
    }
  }

  private static func topPresenter(in windowScene: UIWindowScene) -> UIViewController? {
    let window = windowScene.windows.first(where: \.isKeyWindow) ?? windowScene.windows.first
    guard let window else { return nil }
    return topMostViewController(in: window)
  }

  private static func topMostViewController(in window: UIWindow) -> UIViewController? {
    guard var top = window.rootViewController else { return nil }
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
}
