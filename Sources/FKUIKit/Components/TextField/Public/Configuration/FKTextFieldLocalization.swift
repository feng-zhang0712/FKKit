import Foundation

/// Localizable strings used by `FKTextField`.
///
/// Consumers can replace defaults globally or per-instance to align with product copywriting
/// and localization systems without forking the component.
public struct FKTextFieldLocalization: Sendable, Equatable {
  /// Accessibility label for clear button.
  public var clearButtonLabel: String
  /// Accessibility label for password toggle while hidden.
  public var passwordHiddenLabel: String
  /// Accessibility label for password toggle while visible.
  public var passwordVisibleLabel: String
  /// Prefix used for counter accessibility announcement.
  public var counterAnnouncementPrefix: String
  /// Prefix used for error accessibility announcement.
  public var errorAnnouncementPrefix: String
  /// Prefix used for success accessibility announcement.
  public var successAnnouncementPrefix: String

  /// Creates a localization bundle.
  public init(
    clearButtonLabel: String = FKUIKitI18n.string("fkuikit.textfield.clear_label"),
    passwordHiddenLabel: String = FKUIKitI18n.string("fkuikit.textfield.show_password"),
    passwordVisibleLabel: String = FKUIKitI18n.string("fkuikit.textfield.hide_password"),
    counterAnnouncementPrefix: String = FKUIKitI18n.string("fkuikit.textfield.counter_prefix"),
    errorAnnouncementPrefix: String = FKUIKitI18n.string("fkuikit.textfield.error_prefix"),
    successAnnouncementPrefix: String = FKUIKitI18n.string("fkuikit.textfield.success_prefix")
  ) {
    self.clearButtonLabel = clearButtonLabel
    self.passwordHiddenLabel = passwordHiddenLabel
    self.passwordVisibleLabel = passwordVisibleLabel
    self.counterAnnouncementPrefix = counterAnnouncementPrefix
    self.errorAnnouncementPrefix = errorAnnouncementPrefix
    self.successAnnouncementPrefix = successAnnouncementPrefix
  }
}

