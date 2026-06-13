import UIKit

/// Factory presets for common alert scenarios.
public enum FKAlertPresets {
  /// Destructive delete confirmation with non-dismissible backdrop and swipe disabled by default.
  public static func destructiveConfirm() -> FKAlertConfiguration {
    var configuration = FKAlertConfiguration()
    configuration.presentation.allowsBackdropTapToDismiss = false
    configuration.presentation.allowsSwipeToDismiss = false
    configuration.interaction.hapticOnDestructive = true
    return configuration
  }

  /// Single-action informational alert with backdrop tap dismiss enabled.
  ///
  /// Swipe-to-dismiss stays off: center-card pans are unreliable on compact button stacks.
  /// Set ``FKAlertPresentationConfiguration/allowsSwipeToDismiss`` when swipe is required.
  public static func informational() -> FKAlertConfiguration {
    var configuration = FKAlertConfiguration()
    configuration.presentation.allowsBackdropTapToDismiss = true
    configuration.presentation.allowsSwipeToDismiss = false
    configuration.queue = .singleActive
    return configuration
  }

  /// Rename / prompt style alert with auto-focused text field.
  public static func textPrompt() -> FKAlertConfiguration {
    var configuration = FKAlertConfiguration()
    configuration.presentation.allowsBackdropTapToDismiss = true
    configuration.presentation.allowsSwipeToDismiss = false
    configuration.interaction.autoFocusTextField = true
    return configuration
  }
}
