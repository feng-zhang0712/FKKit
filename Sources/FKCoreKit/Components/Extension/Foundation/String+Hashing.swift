import CryptoKit
import Foundation

public extension String {
  /// Lowercase MD5 digest of the UTF-8 bytes as a hexadecimal string.
  ///
  /// - Note: Uses CryptoKit `Insecure.MD5`. Suitable for cache keys and non-security checksums;
  ///   prefer ``FKHashService`` when cryptographic guarantees or additional algorithms are required.
  var fk_md5: String {
    let digest = Insecure.MD5.hash(data: fk_utf8Data)
    return digest.map { String(format: "%02hhx", $0) }.joined()
  }

  /// Lowercase SHA-256 digest of the UTF-8 bytes as a hexadecimal string.
  var fk_sha256: String {
    let digest = SHA256.hash(data: fk_utf8Data)
    return digest.map { String(format: "%02hhx", $0) }.joined()
  }
}
