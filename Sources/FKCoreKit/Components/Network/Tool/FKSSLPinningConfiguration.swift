import Foundation

/// Hash algorithm used for certificate and public-key pins.
public enum FKPinHashAlgorithm: String, Sendable, Equatable {
  /// SHA-256 digest encoded as Base64.
  case sha256
}

/// Certificate pin entry for a host.
public struct FKCertificatePin: Sendable, Equatable {
  /// Digest algorithm.
  public var algorithm: FKPinHashAlgorithm
  /// Base64-encoded digest of DER certificate bytes.
  public var base64Hash: String

  /// Creates a certificate pin.
  public init(algorithm: FKPinHashAlgorithm = .sha256, base64Hash: String) {
    self.algorithm = algorithm
    self.base64Hash = base64Hash
  }
}

/// Public-key pin entry for a host.
public struct FKPublicKeyPin: Sendable, Equatable {
  /// Digest algorithm.
  public var algorithm: FKPinHashAlgorithm
  /// Base64-encoded SHA-256 digest of `SecKeyCopyExternalRepresentation` bytes.
  public var base64Hash: String

  /// Creates a public-key pin.
  public init(algorithm: FKPinHashAlgorithm = .sha256, base64Hash: String) {
    self.algorithm = algorithm
    self.base64Hash = base64Hash
  }
}

/// Strict SSL pinning configuration applied during authentication challenges.
public struct FKSSLPinningConfiguration: Sendable, Equatable {
  /// Hostnames that require pinning validation.
  public var pinnedHosts: Set<String>
  /// Certificate pins keyed by hostname.
  public var certificateHashes: [String: [FKCertificatePin]]
  /// Public-key pins keyed by hostname.
  public var publicKeyHashes: [String: [FKPublicKeyPin]]
  /// When `true`, subdomains of `pinnedHosts` entries are pinned as well.
  public var enforceForSubdomains: Bool
  /// When `true`, falls back to system trust evaluation after pin mismatch. Default `false`.
  public var allowUserTrustEvaluationFallback: Bool

  /// Creates pinning configuration.
  public init(
    pinnedHosts: Set<String> = [],
    certificateHashes: [String: [FKCertificatePin]] = [:],
    publicKeyHashes: [String: [FKPublicKeyPin]] = [:],
    enforceForSubdomains: Bool = false,
    allowUserTrustEvaluationFallback: Bool = false
  ) {
    self.pinnedHosts = pinnedHosts
    self.certificateHashes = certificateHashes
    self.publicKeyHashes = publicKeyHashes
    self.enforceForSubdomains = enforceForSubdomains
    self.allowUserTrustEvaluationFallback = allowUserTrustEvaluationFallback
  }
}
