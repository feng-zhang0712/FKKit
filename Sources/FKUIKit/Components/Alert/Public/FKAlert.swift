import FKCoreKit
import UIKit

/// Ergonomic entry points for common alert flows.
@MainActor
public enum FKAlert {
  /// Presents a two-action confirmation dialog and returns `true` when the confirm action is chosen.
  public static func confirm(
    title: String,
    message: String?,
    confirmTitle: String,
    cancelTitle: String = FKUIKitI18n.string("fkuikit.common.cancel"),
    isDestructive: Bool = false,
    from presenter: UIViewController? = nil,
    configuration: FKAlertConfiguration = .init()
  ) async -> Bool {
    let confirmAction = FKAlertAction(
      title: confirmTitle,
      style: isDestructive ? .destructive : .default
    )
    let cancelAction = FKAlertAction(title: cancelTitle, style: .cancel)
    let content = FKAlertContent(
      title: title,
      message: message,
      actions: [confirmAction, cancelAction]
    )
    let result = await FKAlertPresenter.shared.present(content, from: presenter, configuration: configuration)
    switch result {
    case .action(_, let action, _) where action.style == .default || action.style == .destructive:
      return true
    default:
      return false
    }
  }

  /// Presents a text prompt and returns trimmed input, or `nil` when cancelled or dismissed.
  public static func prompt(
    title: String?,
    message: String?,
    placeholder: String?,
    confirmTitle: String,
    cancelTitle: String = FKUIKitI18n.string("fkuikit.common.cancel"),
    from presenter: UIViewController? = nil,
    configuration: FKAlertConfiguration = FKAlertPresets.textPrompt()
  ) async -> String? {
    let content = FKAlertContent(
      title: title,
      message: message,
      actions: [
        FKAlertAction(title: confirmTitle, style: .default),
        FKAlertAction(title: cancelTitle, style: .cancel),
      ],
      textInput: FKAlertTextInput(placeholder: placeholder)
    )
    let result = await FKAlertPresenter.shared.present(content, from: presenter, configuration: configuration)
    switch result {
    case .action(_, _, let text):
      return text?.trimmingCharacters(in: .whitespacesAndNewlines)
    default:
      return nil
    }
  }
}
