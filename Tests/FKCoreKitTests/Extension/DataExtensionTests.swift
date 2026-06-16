import FKCoreKit
import XCTest

final class DataExtensionTests: XCTestCase {
  func testHexEncodedStringUsesLowercaseHexDigits() {
    let data = Data([0xAB, 0x0F, 0x00])

    XCTAssertEqual(data.fk_hexEncodedString, "ab0f00")
    XCTAssertEqual(data.fk_hexEncodedStringUppercased, "AB0F00")
  }

  func testInitFromHexEncodedParsesSpacedHexString() {
    let data = Data(fk_hexEncoded: "AB 0F 00")

    XCTAssertEqual(data, Data([0xAB, 0x0F, 0x00]))
  }

  func testInitFromHexEncodedReturnsNilForOddLengthInput() {
    XCTAssertNil(Data(fk_hexEncoded: "ABC"))
  }

  func testUTF8StringDecodesValidBytes() {
    let data = Data("hello".utf8)

    XCTAssertEqual(data.fk_utf8String, "hello")
    XCTAssertFalse(data.fk_byteCountDescription.isEmpty)
  }
}
