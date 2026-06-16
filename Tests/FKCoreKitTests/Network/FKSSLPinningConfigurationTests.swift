import FKCoreKit
import XCTest

final class FKSSLPinningConfigurationTests: XCTestCase {
  func testDefaultConfigurationDisablesSubdomainEnforcementAndTrustFallback() {
    let configuration = FKSSLPinningConfiguration()

    XCTAssertTrue(configuration.pinnedHosts.isEmpty)
    XCTAssertFalse(configuration.enforceForSubdomains)
    XCTAssertFalse(configuration.allowUserTrustEvaluationFallback)
  }

  func testConfigurationStoresPinnedHostsAndHashMaps() {
    let certificatePin = FKCertificatePin(base64Hash: "cert-hash")
    let publicKeyPin = FKPublicKeyPin(base64Hash: "key-hash")
    let configuration = FKSSLPinningConfiguration(
      pinnedHosts: ["api.example.com"],
      certificateHashes: ["api.example.com": [certificatePin]],
      publicKeyHashes: ["api.example.com": [publicKeyPin]],
      enforceForSubdomains: true,
      allowUserTrustEvaluationFallback: true
    )

    XCTAssertEqual(configuration.pinnedHosts, ["api.example.com"])
    XCTAssertEqual(configuration.certificateHashes["api.example.com"]?.first?.base64Hash, "cert-hash")
    XCTAssertEqual(configuration.publicKeyHashes["api.example.com"]?.first?.base64Hash, "key-hash")
    XCTAssertTrue(configuration.enforceForSubdomains)
    XCTAssertTrue(configuration.allowUserTrustEvaluationFallback)
  }
}
