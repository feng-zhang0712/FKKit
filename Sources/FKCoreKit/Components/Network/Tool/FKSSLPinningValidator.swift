import CryptoKit
import Foundation
import Security

/// Validates server trust objects against configured certificate or public-key pins.
public enum FKSSLPinningValidator {
  /// Returns whether the host should be validated with strict pinning rules.
  public static func shouldPin(host: String, config: FKSSLPinningConfiguration) -> Bool {
    if config.pinnedHosts.contains(host) {
      return true
    }
    guard config.enforceForSubdomains else { return false }
    return config.pinnedHosts.contains { pinHost in
      host == pinHost || host.hasSuffix(".\(pinHost)")
    }
  }

  /// Validates trust for a pinned host.
  ///
  /// - Throws: ``NetworkError/sslPinningFailed(host:)`` when no configured pin matches.
  public static func validate(
    trust: SecTrust,
    host: String,
    config: FKSSLPinningConfiguration
  ) throws {
    let certPins = pins(for: host, in: config.certificateHashes, pinnedHosts: config.pinnedHosts, enforceSubdomains: config.enforceForSubdomains)
    let keyPins = pins(for: host, in: config.publicKeyHashes, pinnedHosts: config.pinnedHosts, enforceSubdomains: config.enforceForSubdomains)

    guard certPins.isEmpty == false || keyPins.isEmpty == false else {
      throw NetworkError.sslPinningNotConfigured(host: host)
    }

    guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate], chain.isEmpty == false else {
      throw NetworkError.sslPinningFailed(host: host)
    }

    for certificate in chain {
      if certPins.isEmpty == false, let data = SecCertificateCopyData(certificate) as Data? {
        let hash = Data(SHA256.hash(data: data)).base64EncodedString()
        if certPins.contains(where: { $0.base64Hash == hash }) {
          return
        }
      }

      if keyPins.isEmpty == false, let publicKey = SecCertificateCopyKey(certificate) {
        var error: Unmanaged<CFError>?
        if let keyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? {
          let hash = Data(SHA256.hash(data: keyData)).base64EncodedString()
          if keyPins.contains(where: { $0.base64Hash == hash }) {
            return
          }
        }
      }
    }

    throw NetworkError.sslPinningFailed(host: host)
  }

  private static func pins<T>(
    for host: String,
    in map: [String: [T]],
    pinnedHosts: Set<String>,
    enforceSubdomains: Bool
  ) -> [T] {
    if let direct = map[host] {
      return direct
    }
    guard enforceSubdomains else { return [] }
    for pinHost in pinnedHosts {
      if host == pinHost || host.hasSuffix(".\(pinHost)"), let value = map[pinHost] {
        return value
      }
    }
    return []
  }
}
