import Foundation
import LocalAuthentication

enum FKBiometricErrorMapper {
  static func map(_ error: Error) -> FKBiometricError {
    guard let laError = error as? LAError else {
      let nsError = error as NSError
      return .underlying(code: nsError.code, domain: nsError.domain)
    }

    switch laError.code {
    case .authenticationFailed:
      return .authenticationFailed
    case .userCancel:
      return .userCancelled
    case .userFallback:
      return .userFallback
    case .systemCancel:
      return .systemCancelled
    case .passcodeNotSet:
      return .passcodeNotSet
    case .biometryNotAvailable:
      return .biometryNotAvailable
    case .biometryNotEnrolled:
      return .biometryNotEnrolled
    case .biometryLockout:
      return .biometryLockout
    case .appCancel:
      return .appCancelled
    case .invalidContext:
      return .invalidContext
    case .notInteractive:
      return .notInteractive
    default:
      if laError.errorCode == -11 {
        return .watchNotAvailable
      }
      return .underlying(code: laError.errorCode, domain: LAError.errorDomain)
    }
  }
}
