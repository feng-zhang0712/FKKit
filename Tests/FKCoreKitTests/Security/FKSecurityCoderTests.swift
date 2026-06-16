import FKCoreKit
import XCTest

final class FKSecurityCoderTests: XCTestCase {
  private let coder = FKSecurityCoder()

  func testHexRoundTripPreservesPayload() throws {
    let payload = Data([0xDE, 0xAD, 0xBE, 0xEF])
    let hex = coder.hexString(from: payload, uppercase: true)
    XCTAssertEqual(hex, "DEADBEEF")
    XCTAssertEqual(try coder.data(fromHex: hex), payload)
  }

  func testDataFromHexRejectsOddLengthInput() {
    XCTAssertThrowsError(try coder.data(fromHex: "abc")) { error in
      XCTAssertTrue(error is FKSecurityError)
    }
  }

  func testBase64AndURLEncodingRoundTrip() throws {
    let payload = Data("hello+world".utf8)
    let encoded = coder.base64Encode(payload)
    XCTAssertEqual(try coder.base64Decode(encoded), payload)

    let urlEncoded = coder.urlEncode("a b&c=d")
    XCTAssertTrue(urlEncoded.contains("%"))
    XCTAssertEqual(coder.urlDecode(urlEncoded), "a b&c=d")
  }
}
