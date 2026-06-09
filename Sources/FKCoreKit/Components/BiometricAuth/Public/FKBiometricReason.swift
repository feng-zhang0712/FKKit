import Foundation

/// Localized default reasons for system authentication UI.
public enum FKBiometricReason {
  /// Default reason for unlocking the app.
  public static func unlockApp() -> String {
    FKI18n.string("fkcore.biometric.reason.unlock_app")
  }

  /// Generic confirmation reason (e.g. approve an action).
  public static func confirmAction() -> String {
    FKI18n.string("fkcore.biometric.reason.confirm_action")
  }

  /// Resolves a custom FKI18n key to a localized string.
  public static func custom(_ key: String) -> String {
    FKI18n.string(key)
  }
}
