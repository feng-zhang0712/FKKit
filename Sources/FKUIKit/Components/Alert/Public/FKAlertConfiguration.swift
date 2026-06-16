import UIKit

// MARK: - Root configuration

/// Visual, interaction, presentation, and queue settings for ``FKAlert``.
public struct FKAlertConfiguration: Sendable {
  /// Sheet presentation and dismiss policy.
  public var presentation: FKAlertPresentationConfiguration
  /// Typography, spacing, and scroll limits.
  public var appearance: FKAlertAppearanceConfiguration
  /// Focus, haptics, and handler timing options.
  public var interaction: FKAlertInteractionConfiguration
  /// Overrides applied when embedding ``FKTextField``.
  public var textField: FKAlertTextFieldConfiguration
  /// Queue behavior for concurrent present calls.
  public var queue: FKAlertQueuePolicy
  /// Primary/cancel button layout mode.
  public var buttonLayout: FKAlertButtonLayout
  /// Motion preferences layered on sheet animation.
  public var motion: FKAlertMotionConfiguration
  /// Accessibility announcements and hints.
  public var accessibility: FKAlertAccessibilityConfiguration

  /// Creates an alert configuration with production defaults.
  public init(
    presentation: FKAlertPresentationConfiguration = .init(),
    appearance: FKAlertAppearanceConfiguration = .init(),
    interaction: FKAlertInteractionConfiguration = .init(),
    textField: FKAlertTextFieldConfiguration = .init(),
    queue: FKAlertQueuePolicy = .singleActive,
    buttonLayout: FKAlertButtonLayout = .vertical,
    motion: FKAlertMotionConfiguration = .init(),
    accessibility: FKAlertAccessibilityConfiguration = .init()
  ) {
    self.presentation = presentation
    self.appearance = appearance
    self.interaction = interaction
    self.textField = textField
    self.queue = queue
    self.buttonLayout = buttonLayout
    self.motion = motion
    self.accessibility = accessibility
  }
}

// MARK: - Presentation

/// Sheet integration and backdrop dismiss toggles.
public struct FKAlertPresentationConfiguration: Sendable {
  /// Base sheet configuration. `nil` uses a content-fitted ``FKSheetPresentationConfiguration/centerAlert`` variant at presentation time.
  public var sheet: FKSheetPresentationConfiguration?
  /// Whether tapping the dimmed backdrop dismisses the alert.
  public var allowsBackdropTapToDismiss: Bool
  /// Whether interactive swipe dismisses the alert in center mode.
  ///
  /// Defaults to `false` because center-card swipe is hard to discover on compact alerts
  /// (Sheet pan cannot begin on buttons or text fields). Prefer ``FKAlertPresets/informational()``
  /// backdrop tap for lightweight notices, or set this to `true` when swipe is intentional.
  public var allowsSwipeToDismiss: Bool
  /// Optional override for container corner radius.
  public var cornerRadius: CGFloat?

  /// Creates presentation settings.
  public init(
    sheet: FKSheetPresentationConfiguration? = nil,
    allowsBackdropTapToDismiss: Bool = false,
    allowsSwipeToDismiss: Bool = false,
    cornerRadius: CGFloat? = nil
  ) {
    self.sheet = sheet
    self.allowsBackdropTapToDismiss = allowsBackdropTapToDismiss
    self.allowsSwipeToDismiss = allowsSwipeToDismiss
    self.cornerRadius = cornerRadius
  }
}

// MARK: - Appearance

/// Visual styling for alert chrome.
public struct FKAlertAppearanceConfiguration: Sendable, Equatable {
  /// Title text style.
  public var titleTextStyle: UIFont.TextStyle
  /// Message text style.
  public var messageTextStyle: UIFont.TextStyle
  /// Padding around the alert content stack.
  public var contentInsets: NSDirectionalEdgeInsets
  /// Vertical spacing between icon, title, message, text field, and confirmation rows.
  public var bodyItemSpacing: CGFloat
  /// Vertical spacing between the body stack and the action button stack.
  public var actionSectionSpacing: CGFloat
  /// Spacing between action buttons.
  public var buttonSpacing: CGFloat
  /// Square icon dimension.
  public var iconSize: CGFloat
  /// Optional maximum message label height. `nil` uses a viewport sized for comfortable scrolling
  /// (about 12 lines, capped relative to screen height) before the alert body scrolls.
  public var maxMessageHeight: CGFloat?
  /// Title text color.
  public var titleColor: UIColor
  /// Message text color.
  public var messageColor: UIColor
  /// Alert panel background color.
  public var backgroundColor: UIColor

  /// Creates appearance settings.
  public init(
    titleTextStyle: UIFont.TextStyle = .headline,
    messageTextStyle: UIFont.TextStyle = .body,
    contentInsets: NSDirectionalEdgeInsets = .init(top: 20, leading: 20, bottom: 20, trailing: 20),
    bodyItemSpacing: CGFloat = 8,
    actionSectionSpacing: CGFloat = 20,
    buttonSpacing: CGFloat = 8,
    iconSize: CGFloat = 40,
    maxMessageHeight: CGFloat? = nil,
    titleColor: UIColor = .label,
    messageColor: UIColor = .secondaryLabel,
    backgroundColor: UIColor = .systemBackground
  ) {
    self.titleTextStyle = titleTextStyle
    self.messageTextStyle = messageTextStyle
    self.contentInsets = contentInsets
    self.bodyItemSpacing = bodyItemSpacing
    self.actionSectionSpacing = actionSectionSpacing
    self.buttonSpacing = buttonSpacing
    self.iconSize = iconSize
    self.maxMessageHeight = maxMessageHeight
    self.titleColor = titleColor
    self.messageColor = messageColor
    self.backgroundColor = backgroundColor
  }
}

// MARK: - Interaction

/// Focus, dismiss, and feedback behavior.
public struct FKAlertInteractionConfiguration: Sendable, Equatable {
  /// Automatically focuses the text field shortly after presentation.
  public var autoFocusTextField: Bool
  /// Dismisses the alert after a successful primary/destructive action.
  public var dismissOnPrimaryAction: Bool
  /// Plays warning haptics after destructive validation succeeds.
  public var hapticOnDestructive: Bool
  /// Minimum delay before invoking a destructive handler (anti mis-tap). `0` disables the delay.
  public var destructiveHandlerDelay: TimeInterval

  /// Creates interaction settings.
  public init(
    autoFocusTextField: Bool = true,
    dismissOnPrimaryAction: Bool = true,
    hapticOnDestructive: Bool = false,
    destructiveHandlerDelay: TimeInterval = 0
  ) {
    self.autoFocusTextField = autoFocusTextField
    self.dismissOnPrimaryAction = dismissOnPrimaryAction
    self.hapticOnDestructive = hapticOnDestructive
    self.destructiveHandlerDelay = max(0, destructiveHandlerDelay)
  }
}

// MARK: - Text field

/// Appearance subset applied to embedded ``FKTextField`` instances.
public struct FKAlertTextFieldConfiguration: Sendable, Equatable {
  /// When `true`, uses a shorter 40pt text area suited to alert prompts. Inline validation errors remain enabled.
  public var usesCompactPreset: Bool

  /// Creates text field overrides.
  public init(usesCompactPreset: Bool = true) {
    self.usesCompactPreset = usesCompactPreset
  }
}

// MARK: - Queue

/// Queueing strategy when multiple alerts are requested.
public enum FKAlertQueuePolicy: Sendable, Equatable {
  /// Waits until the active alert dismisses (FIFO queue).
  case singleActive
  /// Dismisses the active alert without invoking handlers, then presents the new alert.
  case replaceCurrent
  /// Allows stacked center modals (discouraged).
  case allowStack
  /// Skips presentation when the same `id` is already visible.
  case presentOnceByID
}

// MARK: - Button layout

/// Action button arrangement.
public enum FKAlertButtonLayout: Sendable, Equatable {
  /// Full-width vertical stack (default).
  case vertical
  /// Side-by-side layout for exactly two non-destructive actions.
  case horizontalPair
}

// MARK: - Motion

/// Motion preferences layered on sheet transitions.
public struct FKAlertMotionConfiguration: Sendable, Equatable {
  /// Uses cross-fade only when Reduce Motion is enabled.
  public var respectsReduceMotion: Bool

  /// Creates motion settings.
  public init(respectsReduceMotion: Bool = true) {
    self.respectsReduceMotion = respectsReduceMotion
  }
}

// MARK: - Accessibility

/// VoiceOver and announcement behavior.
public struct FKAlertAccessibilityConfiguration: Sendable, Equatable {
  /// Posts a screen-changed announcement with title and message on appear.
  public var announcesOnPresent: Bool
  /// Optional hint appended to destructive buttons.
  public var destructiveHint: String?

  /// Creates accessibility settings.
  public init(
    announcesOnPresent: Bool = true,
    destructiveHint: String? = FKUIKitI18n.string("fkuikit.alert.destructive_hint")
  ) {
    self.announcesOnPresent = announcesOnPresent
    self.destructiveHint = destructiveHint
  }
}
