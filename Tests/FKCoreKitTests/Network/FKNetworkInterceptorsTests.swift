import FKCoreKit
import XCTest

final class FKNetworkInterceptorsTests: XCTestCase {
  private final class MockTokenStore: TokenStore {
    var accessToken: String?
    var refreshToken: String?
  }

  func testAuthHeaderInterceptorAddsBearerTokenWhenPresent() throws {
    let store = MockTokenStore()
    store.accessToken = "abc123"
    let interceptor = AuthHeaderInterceptor(tokenStore: store)
    let request = URLRequest(url: URL(string: "https://api.example.com/v1/profile")!)

    let updated = try interceptor.intercept(request)

    XCTAssertEqual(updated.value(forHTTPHeaderField: "Authorization"), "Bearer abc123")
  }

  func testAuthHeaderInterceptorSkipsHeaderWhenTokenMissingOrEmpty() throws {
    let store = MockTokenStore()
    store.accessToken = ""
    let interceptor = AuthHeaderInterceptor(tokenStore: store)
    let request = URLRequest(url: URL(string: "https://api.example.com/v1/profile")!)

    let updated = try interceptor.intercept(request)

    XCTAssertNil(updated.value(forHTTPHeaderField: "Authorization"))
  }

  func testMD5RequestSignerAddsTimestampAndSignatureHeaders() throws {
    let signer = MD5RequestSigner(secret: "unit-test-secret")
    var request = URLRequest(url: URL(string: "https://api.example.com/v1/users?page=1")!)
    request.httpMethod = "POST"

    let signed = try signer.sign(request)
    let timestamp = signed.value(forHTTPHeaderField: "X-Timestamp")
    let signature = signed.value(forHTTPHeaderField: "X-Signature")

    XCTAssertNotNil(timestamp)
    XCTAssertNotNil(signature)
    let source = "POST|/v1/users|\(timestamp!)|unit-test-secret"
    XCTAssertEqual(signature, source.fk_md5)
  }

  func testMD5RequestSignerThrowsWhenURLMissing() {
    let signer = MD5RequestSigner(secret: "secret")
    var request = URLRequest(url: URL(string: "about:blank")!)
    request.url = nil

    XCTAssertThrowsError(try signer.sign(request)) { error in
      guard case NetworkError.signingFailed = error else {
        return XCTFail("Expected signingFailed, got \(error)")
      }
    }
  }
}
