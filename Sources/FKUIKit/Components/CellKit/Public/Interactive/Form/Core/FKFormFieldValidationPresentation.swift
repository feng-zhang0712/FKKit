import Foundation

/// Inline validation copy and required markers below form fields (X-21–X-25).
public struct FKFormFieldValidationPresentation: Sendable, Equatable {
  public var isRequired: Bool
  public var helperText: String?
  public var errorText: String?
  public var successText: String?
  public var showsRequiredIndicator: Bool
  public var passwordStrength: FKPasswordStrength?

  /// Creates a validation presentation snapshot.
  public init(
    isRequired: Bool = false,
    helperText: String? = nil,
    errorText: String? = nil,
    successText: String? = nil,
    showsRequiredIndicator: Bool = true,
    passwordStrength: FKPasswordStrength? = nil
  ) {
    self.isRequired = isRequired
    self.helperText = helperText
    self.errorText = errorText
    self.successText = successText
    self.showsRequiredIndicator = showsRequiredIndicator
    self.passwordStrength = passwordStrength
  }
}
