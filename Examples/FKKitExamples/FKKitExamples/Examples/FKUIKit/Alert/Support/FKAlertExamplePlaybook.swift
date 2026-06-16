import FKCoreKit
import UIKit
import FKUIKit

/// Reusable alert payloads for FKAlert examples.
enum FKAlertExamplePlaybook {
  static func informationalContent() -> FKAlertContent {
    FKAlertContent(
      title: "Update available",
      message: "A newer version is ready to install.",
      actions: []
    )
  }

  static func destructiveDeleteContent() -> FKAlertContent {
    FKAlertContent(
      title: "Delete photo?",
      message: "This photo will be removed from your library.",
      icon: .systemName("trash.fill", tint: .destructive),
      actions: [
        FKAlertAction(title: "Delete", style: .destructive) {
          Task { @MainActor in FKAlertExampleLog.log("handler: Delete tapped") }
        },
        FKAlertAction(title: "Cancel", style: .cancel),
      ]
    )
  }

  static func renamePromptContent(initial: String = "Holiday album") -> FKAlertContent {
    FKAlertContent(
      title: "Rename album",
      message: "Choose a name your friends will recognize.",
      actions: [
        FKAlertAction(title: "Save", style: .default) {
          Task { @MainActor in FKAlertExampleLog.log("handler: Save rename") }
        },
        FKAlertAction(title: "Cancel", style: .cancel),
      ],
      textInput: FKAlertTextInput(
        placeholder: "Album name",
        initialText: initial,
        returnKeyType: .done
      )
    )
  }

  static func validationPromptContent() -> FKAlertContent {
    FKAlertContent(
      title: "Choose a handle",
      message: "Use 3–16 letters or numbers.",
      actions: [
        FKAlertAction(title: "Continue", style: .default),
        FKAlertAction(title: "Cancel", style: .cancel),
      ],
      textInput: FKAlertTextInput(
        placeholder: "handle",
        initialText: "ab",
        autocapitalization: .none,
        validation: FKAlertTextValidation(
          validate: { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 3, trimmed.count <= 16 else { return false }
            return trimmed.range(of: "^[A-Za-z0-9]+$", options: .regularExpression) != nil
          },
          failureMessage: "Enter 3–16 alphanumeric characters."
        )
      )
    )
  }

  static func longLegalContent() -> FKAlertContent {
    let paragraphs = (1...8).map { index in
      "Section \(index). By continuing you acknowledge that demo legal copy can be long. FKAlert grows to fit short content and scrolls the body only when the fitted max height or screen bounds are exceeded."
    }
    return FKAlertContent(
      title: "Terms & privacy",
      message: paragraphs.joined(separator: "\n\n"),
      actions: [
        FKAlertAction(title: "Agree", style: .default),
        FKAlertAction(title: "Decline", style: .cancel),
      ]
    )
  }

  static func checkboxGatedDeleteContent() -> FKAlertContent {
    FKAlertContent(
      title: "Delete account?",
      message: "All profile data and purchases will be permanently removed.",
      icon: .systemName("exclamationmark.triangle.fill", tint: .warning),
      actions: [
        FKAlertAction(title: "Delete account", style: .destructive) {
          Task { @MainActor in FKAlertExampleLog.log("handler: Account deleted") }
        },
        FKAlertAction(title: "Cancel", style: .cancel),
      ],
      dangerousAction: FKAlertDangerousActionOptions(
        requiresConfirmationCheckbox: true,
        checkboxTitle: "I understand this cannot be undone."
      )
    )
  }

  static func horizontalPairContent() -> FKAlertContent {
    FKAlertContent(
      title: "Save draft?",
      message: "You have unsaved changes.",
      actions: [
        FKAlertAction(title: "Save", style: .default),
        FKAlertAction(title: "Discard", style: .default),
      ]
    )
  }

  static func attributedMessageContent() -> NSAttributedString {
    let message = NSMutableAttributedString(
      string: "Refund policy applies to unused credits only. ",
      attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
    )
    message.append(
      NSAttributedString(
        string: "Contact support",
        attributes: [
          .font: UIFont.preferredFont(forTextStyle: .body),
          .foregroundColor: UIColor.systemBlue,
        ]
      )
    )
    message.append(
      NSAttributedString(
        string: " for exceptions.",
        attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
      )
    )
    return message
  }

  static func syncErrorContent(id: String = "network-sync-error") -> FKAlertContent {
    FKAlertContent(
      id: id,
      title: "Sync failed",
      message: "Check your connection and try again.",
      actions: [FKAlertAction(title: "OK", style: .default)]
    )
  }

  static func queueContent(title: String, message: String) -> FKAlertContent {
    FKAlertContent(
      title: title,
      message: message,
      actions: [FKAlertAction(title: "OK", style: .default)]
    )
  }

  static func accessibilityDemoContent() -> FKAlertContent {
    FKAlertContent(
      title: "Verify phone number",
      message: "We will send a one-time code.",
      actions: [
        FKAlertAction(title: "Send code", style: .default),
        FKAlertAction(title: "Cancel", style: .cancel),
      ],
      textInput: FKAlertTextInput(
        placeholder: "+1 phone number",
        keyboardType: .phonePad,
        textContentType: .telephoneNumber
      )
    )
  }
}
