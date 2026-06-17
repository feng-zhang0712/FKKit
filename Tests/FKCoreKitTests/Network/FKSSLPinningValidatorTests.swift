import CryptoKit
import FKCoreKit
import Security
import XCTest

final class FKSSLPinningValidatorTests: XCTestCase {
  private enum Fixture {
    static let host = "example.com"
    static let certificateDER = Data(base64Encoded: """
      MIIDDTCCAfWgAwIBAgIUOZvhhNaznvk1c6DDECQN2G6EWyowDQYJKoZIhvcNAQELBQAwFjEUMBIGA1UEAwwLZXhhbXBsZS5jb20wHhcNMjYwNjE3MDQzODAwWhcNMzYwNjE0MDQzODAwWjAWMRQwEgYDVQQDDAtleGFtcGxlLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKBkR2ukupxGYyaD0Ld4m+b0TshFGrrK/AmS3ldSrTxtL3URs/8DNZXfzVjJFgN3bxx6dwfsCkyeqb68fgbuxglayX/AK73+kNABNFxgA63MRTu7MgJhKeoISCotHrAHcnlzhDJ6JsZ7XvDWh5IfVbVkdWRsd2q+T/cGjsBGvh5w1rJgO5kWp8Lv6WxyLt4JnHpKOMBKwfR/AmRyuqZgBzzC4HxGKQ+u4j9zApHVJpRZ2KGOLpF7ZoPFDIP1JwP1tbAdWufnjDUadQ4femitJ0ILMuOS2MQplVp9hU69NFGGJ01jOC4U9ypVOsBNfY/0MdbAaKWZurOIVOJB9br92dkCAwEAAaNTMFEwHQYDVR0OBBYEFIPrnypy6qUDdQf51CLTk7yFav04MB8GA1UdIwQYMBaAFIPrnypy6qUDdQf51CLTk7yFav04MA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAH713dWVir62CvOB8m5Ey4z0HNkovlno9ps4WW4inUXCTZaWQks3Ck6arsKcdw1UVwnyfV705eYeE0cprG9ruErfLx9gTiWAbqgIdVCtEL5M84Bmy2Cd5MvdVBfXuigbVPX0CRD6VSZiznKn8Cm5tsb6ZWBpKFNVEhKHFo9+rg0cz30VsxDa4j2ohSFeJN6lexZznR+Y6CoiYYfmLiyprBz6Q7z5mZgzabfXkFBfndftRyNvIfIHNml4R9YtRHRasrd7ujYSvlbahd27aWjxkeQy0xGxaQ564O+eQQY4QUIFFYXjIv2qwVrQpv8vfLsvjO8tWO3Xd9dWvMfv3Z8BYk0=
      """)! // gitleaks:allow

    static var certificatePinHash: String {
      guard let certificate = SecCertificateCreateWithData(nil, certificateDER as CFData),
            let data = SecCertificateCopyData(certificate) as Data?
      else {
        XCTFail("Failed to load fixture certificate")
        return ""
      }
      return Data(SHA256.hash(data: data)).base64EncodedString()
    }

    static var publicKeyPinHash: String {
      guard let certificate = SecCertificateCreateWithData(nil, certificateDER as CFData),
            let publicKey = SecCertificateCopyKey(certificate)
      else {
        XCTFail("Failed to load fixture public key")
        return ""
      }
      var error: Unmanaged<CFError>?
      guard let keyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
        XCTFail("Failed to export fixture public key")
        return ""
      }
      return Data(SHA256.hash(data: keyData)).base64EncodedString()
    }

    static func makeTrust(host: String = host) throws -> SecTrust {
      guard let certificate = SecCertificateCreateWithData(nil, certificateDER as CFData) else {
        throw FixtureError.certificateCreationFailed
      }
      var trust: SecTrust?
      let policy = SecPolicyCreateSSL(true, host as CFString)
      let status = SecTrustCreateWithCertificates([certificate] as CFArray, policy, &trust)
      guard status == errSecSuccess, let trust else {
        throw FixtureError.trustCreationFailed
      }
      return trust
    }
  }

  private enum FixtureError: Error {
    case certificateCreationFailed
    case trustCreationFailed
  }

  func testShouldPinReturnsTrueForDirectPinnedHost() {
    let config = FKSSLPinningConfiguration(pinnedHosts: [Fixture.host])

    XCTAssertTrue(FKSSLPinningValidator.shouldPin(host: Fixture.host, config: config))
  }

  func testShouldPinReturnsFalseForUnrelatedHostWhenSubdomainsDisabled() {
    let config = FKSSLPinningConfiguration(
      pinnedHosts: [Fixture.host],
      enforceForSubdomains: false
    )

    XCTAssertFalse(FKSSLPinningValidator.shouldPin(host: "api.example.com", config: config))
  }

  func testShouldPinMatchesSubdomainWhenEnforcementEnabled() {
    let config = FKSSLPinningConfiguration(
      pinnedHosts: [Fixture.host],
      enforceForSubdomains: true
    )

    XCTAssertTrue(FKSSLPinningValidator.shouldPin(host: "api.example.com", config: config))
  }

  func testValidateThrowsNotConfiguredWhenHostPinnedWithoutHashes() {
    let config = FKSSLPinningConfiguration(pinnedHosts: [Fixture.host])

    do {
      try FKSSLPinningValidator.validate(
        trust: try Fixture.makeTrust(),
        host: Fixture.host,
        config: config
      )
      XCTFail("Expected sslPinningNotConfigured")
    } catch NetworkError.sslPinningNotConfigured(let host) {
      XCTAssertEqual(host, Fixture.host)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testValidateSucceedsWhenCertificateHashMatches() throws {
    let config = FKSSLPinningConfiguration(
      pinnedHosts: [Fixture.host],
      certificateHashes: [
        Fixture.host: [FKCertificatePin(base64Hash: Fixture.certificatePinHash)],
      ]
    )

    XCTAssertNoThrow(
      try FKSSLPinningValidator.validate(
        trust: try Fixture.makeTrust(),
        host: Fixture.host,
        config: config
      )
    )
  }

  func testValidateSucceedsWhenPublicKeyHashMatches() throws {
    let config = FKSSLPinningConfiguration(
      pinnedHosts: [Fixture.host],
      publicKeyHashes: [
        Fixture.host: [FKPublicKeyPin(base64Hash: Fixture.publicKeyPinHash)],
      ]
    )

    XCTAssertNoThrow(
      try FKSSLPinningValidator.validate(
        trust: try Fixture.makeTrust(),
        host: Fixture.host,
        config: config
      )
    )
  }

  func testValidateThrowsFailedWhenConfiguredHashDoesNotMatch() throws {
    let config = FKSSLPinningConfiguration(
      pinnedHosts: [Fixture.host],
      certificateHashes: [
        Fixture.host: [FKCertificatePin(base64Hash: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")],
      ]
    )

    do {
      try FKSSLPinningValidator.validate(
        trust: try Fixture.makeTrust(),
        host: Fixture.host,
        config: config
      )
      XCTFail("Expected sslPinningFailed")
    } catch NetworkError.sslPinningFailed(let host) {
      XCTAssertEqual(host, Fixture.host)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testValidateResolvesSubdomainPinsWhenEnforcementEnabled() throws {
    let subdomain = "api.example.com"
    let config = FKSSLPinningConfiguration(
      pinnedHosts: [Fixture.host],
      certificateHashes: [
        Fixture.host: [FKCertificatePin(base64Hash: Fixture.certificatePinHash)],
      ],
      enforceForSubdomains: true
    )

    XCTAssertNoThrow(
      try FKSSLPinningValidator.validate(
        trust: try Fixture.makeTrust(host: subdomain),
        host: subdomain,
        config: config
      )
    )
  }
}
