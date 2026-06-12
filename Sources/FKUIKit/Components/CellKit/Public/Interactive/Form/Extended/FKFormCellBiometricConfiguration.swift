import Foundation

/// Configuration for ``FKFormCellBiometricCell`` (X-60).
public struct FKFormCellBiometricConfiguration: Sendable, Equatable {
  public var label: String?
  public var buttonTitle: String
  public var authReason: String
  public var errorText: String?
  public var isEnabled: Bool

  public init(
    label: String? = "Biometric Sign-In",
    buttonTitle: String = "Authenticate",
    authReason: String = "Confirm your identity",
    errorText: String? = nil,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.buttonTitle = buttonTitle
    self.authReason = authReason
    self.errorText = errorText
    self.isEnabled = isEnabled
  }
}
