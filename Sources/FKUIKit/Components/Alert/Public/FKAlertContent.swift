import FKCoreKit
import UIKit

// MARK: - Content

/// Declarative alert content model.
public struct FKAlertContent: Sendable {
  /// Optional stable identifier for queue de-duplication (`presentOnce`).
  public var id: String?
  /// Optional headline title.
  public var title: String?
  /// Plain-text message body.
  public var message: String?
  /// Optional archived `NSAttributedString` payload. When set, overrides `message`.
  public var attributedMessage: Data?
  /// Optional leading icon.
  public var icon: FKAlertIcon?
  /// Action descriptors. Empty arrays receive a default OK action at presentation time.
  public var actions: [FKAlertAction]
  /// Optional single-line text field configuration.
  public var textInput: FKAlertTextInput?
  /// Optional destructive-action safeguards.
  public var dangerousAction: FKAlertDangerousActionOptions?
  /// Accessibility identifier applied to the alert root view.
  public var accessibilityIdentifier: String?

  /// Creates alert content.
  public init(
    id: String? = nil,
    title: String? = nil,
    message: String? = nil,
    attributedMessage: Data? = nil,
    icon: FKAlertIcon? = nil,
    actions: [FKAlertAction] = [],
    textInput: FKAlertTextInput? = nil,
    dangerousAction: FKAlertDangerousActionOptions? = nil,
    accessibilityIdentifier: String? = nil
  ) {
    self.id = id
    self.title = title
    self.message = message
    self.attributedMessage = attributedMessage
    self.icon = icon
    self.actions = actions
    self.textInput = textInput
    self.dangerousAction = dangerousAction
    self.accessibilityIdentifier = accessibilityIdentifier
  }
}

// MARK: - Icon

/// Optional alert icon source.
public enum FKAlertIcon: Sendable, Equatable {
  /// No icon.
  case none
  /// SF Symbol with optional semantic tint.
  case systemName(String, tint: FKAlertIconTint?)
  /// Named asset from a bundle.
  case asset(name: String, bundle: Bundle?)
}

/// Semantic tint presets for alert icons.
public enum FKAlertIconTint: Sendable, Equatable {
  /// Primary label tint.
  case primary
  /// Warning tint (typically orange).
  case warning
  /// Destructive tint (typically red).
  case destructive
}

// MARK: - Text input

/// Single-line text field options for prompt-style alerts.
public struct FKAlertTextInput: Sendable {
  /// Placeholder text.
  public var placeholder: String?
  /// Initial field value.
  public var initialText: String?
  /// Secure entry toggle.
  public var isSecure: Bool
  /// Keyboard type.
  public var keyboardType: UIKeyboardType
  /// Text content type.
  public var textContentType: UITextContentType?
  /// Autocapitalization behavior.
  public var autocapitalization: UITextAutocapitalizationType
  /// Return key type.
  public var returnKeyType: UIReturnKeyType
  /// Maximum raw text length.
  public var maxLength: Int?
  /// Optional validation executed before primary/destructive dismissal.
  public var validation: FKAlertTextValidation?

  /// Creates text input options.
  public init(
    placeholder: String? = nil,
    initialText: String? = nil,
    isSecure: Bool = false,
    keyboardType: UIKeyboardType = .default,
    textContentType: UITextContentType? = nil,
    autocapitalization: UITextAutocapitalizationType = .sentences,
    returnKeyType: UIReturnKeyType = .done,
    maxLength: Int? = nil,
    validation: FKAlertTextValidation? = nil
  ) {
    self.placeholder = placeholder
    self.initialText = initialText
    self.isSecure = isSecure
    self.keyboardType = keyboardType
    self.textContentType = textContentType
    self.autocapitalization = autocapitalization
    self.returnKeyType = returnKeyType
    self.maxLength = maxLength
    self.validation = validation
  }
}

/// Validation rule executed on the main actor before dismiss.
public struct FKAlertTextValidation: Sendable {
  /// Returns `true` when trimmed input is acceptable.
  public var validate: @Sendable (String) -> Bool
  /// Optional inline failure message shown through ``FKTextField`` error UI.
  public var failureMessage: String?

  /// Creates a validation rule.
  public init(
    validate: @escaping @Sendable (String) -> Bool,
    failureMessage: String? = nil
  ) {
    self.validate = validate
    self.failureMessage = failureMessage
  }
}

// MARK: - Dangerous action

/// Options that gate or emphasize destructive actions.
public struct FKAlertDangerousActionOptions: Sendable, Equatable {
  /// When `true`, destructive buttons stay disabled until the confirmation switch is on.
  public var requiresConfirmationCheckbox: Bool
  /// Label beside the confirmation switch.
  public var checkboxTitle: String
  /// Index into the resolved action list for the destructive action. `nil` selects the first destructive action.
  public var destructiveActionIndex: Int?

  /// Creates dangerous-action options.
  public init(
    requiresConfirmationCheckbox: Bool = false,
    checkboxTitle: String = FKUIKitI18n.string("fkuikit.alert.dangerous_checkbox_default"),
    destructiveActionIndex: Int? = nil
  ) {
    self.requiresConfirmationCheckbox = requiresConfirmationCheckbox
    self.checkboxTitle = checkboxTitle
    self.destructiveActionIndex = destructiveActionIndex
  }
}
