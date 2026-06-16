import FKCoreKit
import XCTest

final class FKSignatureServiceTests: XCTestCase {
  private var security: FKSecurity!

  override func setUp() {
    super.setUp()
    security = FKSecurity()
  }

  override func tearDown() {
    security = nil
    super.tearDown()
  }

  func testHmacHexIsDeterministicForSameInput() async throws {
    let data = Data("payload".utf8)
    let key = Data("secret".utf8)

    let first = try await security.sign.hmacHex(data, key: key, algorithm: .sha256)
    let second = try await security.sign.hmacHex(data, key: key, algorithm: .sha256)

    XCTAssertEqual(first, second)
    XCTAssertEqual(first.count, 64)
  }

  func testVerifyParametersAcceptsMatchingSignature() async throws {
    let parameters = ["name": "FKKit", "version": 1] as [String: Any]
    let secret = "server-shared-secret"
    let signature = try await security.sign.signParameters(parameters, secret: secret, algorithm: .sha256)

    let verified = try await security.sign.verifyParameters(
      parameters,
      secret: secret,
      signatureHex: signature,
      algorithm: .sha256
    )
    XCTAssertTrue(verified)
  }

  func testVerifyParametersRejectsTamperedSignature() async throws {
    let parameters = ["token": "abc"] as [String: Any]
    let signature = try await security.sign.signParameters(parameters, secret: "secret", algorithm: .sha256)

    let verified = try await security.sign.verifyParameters(
      parameters,
      secret: "secret",
      signatureHex: signature + "ff",
      algorithm: .sha256
    )
    XCTAssertFalse(verified)
  }
}
