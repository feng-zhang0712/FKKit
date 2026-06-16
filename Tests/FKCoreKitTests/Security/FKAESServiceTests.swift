import FKCoreKit
import XCTest

final class FKAESServiceTests: XCTestCase {
  private var security: FKSecurity!

  override func setUp() {
    super.setUp()
    security = FKSecurity()
  }

  override func tearDown() {
    security = nil
    super.tearDown()
  }

  func testAESEncryptDecryptRoundTripCBC() async throws {
    let plaintext = "FKKit AES round-trip"
    let ciphertext = try await security.aesEncrypt(
      plaintext,
      key: Fixtures.Security.aes256Key,
      iv: Fixtures.Security.aesIV,
      mode: .cbc
    )
    XCTAssertFalse(ciphertext.isEmpty)

    let decrypted = try await security.aesDecrypt(
      ciphertext,
      key: Fixtures.Security.aes256Key,
      iv: Fixtures.Security.aesIV,
      mode: .cbc
    )
    XCTAssertEqual(decrypted, plaintext)
  }
}
