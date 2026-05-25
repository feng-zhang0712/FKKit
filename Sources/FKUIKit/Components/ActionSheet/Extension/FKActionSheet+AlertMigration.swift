import UIKit

// MARK: - UIAlertController migration

public extension FKActionSheetAction {
  /// Creates an action from parameters matching `UIAlertAction` construction.
  init(
    title: String,
    uiAlertActionStyle: UIAlertAction.Style,
    handler: (@MainActor () -> Void)? = nil,
    actionHandler: (@MainActor (FKActionSheetAction) -> Void)? = nil
  ) {
    self.init(
      title: title,
      style: Style(uiAlertActionStyle: uiAlertActionStyle),
      handler: handler,
      actionHandler: actionHandler
    )
  }
}

public extension FKActionSheetConfiguration {
  /// Builds a configuration similar to `UIAlertController` with `.actionSheet` style.
  ///
  /// - Parameters:
  ///   - title: Optional alert title.
  ///   - message: Optional alert message.
  ///   - actions: Non-cancel actions.
  ///   - cancelTitle: When non-`nil`, appended as a separated cancel row.
  init(
    alertTitle: String?,
    message: String?,
    actions: [FKActionSheetAction],
    cancelTitle: String? = "Cancel"
  ) {
    let header: FKActionSheetHeaderContent? = {
      guard alertTitle != nil || message != nil else { return nil }
      return .text(FKActionSheetHeader(title: alertTitle, message: message))
    }()
    let cancelAction: FKActionSheetAction? = cancelTitle.map {
      FKActionSheetAction(title: $0, style: .cancel)
    }
    self.init(
      header: header,
      sections: [FKActionSheetSection(actions: actions)],
      cancelAction: cancelAction
    )
  }

  /// Builds a configuration from `UIAlertAction`-style tuples.
  init(
    alertTitle: String?,
    message: String?,
    alertActions: [(title: String, style: UIAlertAction.Style, handler: (@MainActor () -> Void)?)],
    cancelTitle: String? = "Cancel"
  ) {
    let mapped = alertActions.map { item in
      FKActionSheetAction(
        title: item.title,
        uiAlertActionStyle: item.style,
        handler: item.handler
      )
    }
    self.init(alertTitle: alertTitle, message: message, actions: mapped, cancelTitle: cancelTitle)
  }
}
