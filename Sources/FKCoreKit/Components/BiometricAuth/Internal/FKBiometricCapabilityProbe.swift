import Foundation
import LocalAuthentication

enum FKBiometricCapabilityProbe {
  static func probe(policy: FKBiometricPolicy) -> FKBiometricCapability {
    let context = LAContext()
    let laPolicy = policy.laPolicy(allowPasscodeFallback: true)

    var probeNSError: NSError?
    let canAuthenticate = context.canEvaluatePolicy(laPolicy, error: &probeNSError)

    let biometryType = context.biometryType.fkBiometryType
    let isBiometryEnrolled = Self.isBiometryEnrolled()
    let isPasscodeSet = Self.isPasscodeSet()

    let probeError: FKBiometricError? = {
      guard !canAuthenticate, let probeNSError else { return nil }
      return FKBiometricErrorMapper.map(probeNSError)
    }()

    return FKBiometricCapability(
      canAuthenticate: canAuthenticate,
      biometryType: biometryType,
      isBiometryEnrolled: isBiometryEnrolled,
      isPasscodeSet: isPasscodeSet,
      evaluatedPolicy: policy,
      probeError: probeError
    )
  }

  private static func isBiometryEnrolled() -> Bool {
    let context = LAContext()
    var error: NSError?
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      return true
    }
    if let error, FKBiometricErrorMapper.map(error) == .biometryNotEnrolled {
      return false
    }
    return false
  }

  private static func isPasscodeSet() -> Bool {
    let context = LAContext()
    var error: NSError?
    _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    if let error, FKBiometricErrorMapper.map(error) == .passcodeNotSet {
      return false
    }
    return true
  }
}
