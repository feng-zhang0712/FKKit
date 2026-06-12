import Foundation
import LocalAuthentication

extension FKBiometricPolicy {
  func laPolicy(allowPasscodeFallback: Bool) -> LAPolicy {
    switch self {
    case .biometricsOnly:
      return .deviceOwnerAuthenticationWithBiometrics
    case .biometricsOrPasscode:
      if allowPasscodeFallback {
        return .deviceOwnerAuthentication
      }
      return .deviceOwnerAuthenticationWithBiometrics
    case .devicePasscode:
      return .deviceOwnerAuthentication
    }
  }
}

extension LABiometryType {
  var fkBiometryType: FKBiometryType {
    switch self {
    case .none:
      return .none
    case .touchID:
      return .touchID
    case .faceID:
      return .faceID
    default:
      if #available(iOS 17.0, *), self == .opticID {
        return .opticID
      }
      return .none
    }
  }
}

extension LAContext {
  static func fk_makeConfigured(
    configuration: FKBiometricAuthConfiguration,
    options: FKBiometricAuthOptions
  ) -> LAContext {
    let context = LAContext()
    context.fk_apply(configuration: configuration, options: options)
    return context
  }

  func fk_apply(
    configuration: FKBiometricAuthConfiguration,
    options: FKBiometricAuthOptions
  ) {
    if let title = options.localizedFallbackTitle ?? configuration.localizedFallbackTitle {
      localizedFallbackTitle = title
    }

    if let reuse = options.reuseDuration ?? configuration.reuseDuration, reuse > 0 {
      touchIDAuthenticationAllowableReuseDuration = reuse
    }
  }
}
