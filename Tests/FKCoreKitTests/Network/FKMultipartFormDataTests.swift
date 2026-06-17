import FKCoreKit
import XCTest

final class FKMultipartFormDataTests: XCTestCase {
  func testEncodeBuildsFieldAndFilePartsWithBoundary() {
    var form = FKMultipartFormData(boundary: "TestBoundary")
    form.append("Ada", name: "name")
    form.append(Data("payload".utf8), name: "avatar", fileName: "avatar.png", mimeType: "image/png")

    let encoded = form.encode()
    let bodyString = String(decoding: encoded.body, as: UTF8.self)

    XCTAssertEqual(encoded.contentType, "multipart/form-data; boundary=TestBoundary")
    XCTAssertTrue(bodyString.contains("--TestBoundary\r\n"))
    XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"name\"\r\n\r\nAda\r\n"))
    XCTAssertTrue(bodyString.contains("filename=\"avatar.png\""))
    XCTAssertTrue(bodyString.contains("Content-Type: image/png"))
    XCTAssertTrue(bodyString.contains("payload"))
    XCTAssertTrue(bodyString.hasSuffix("--TestBoundary--\r\n"))
  }

  func testEncodeEscapesQuotesInFieldNames() {
    var form = FKMultipartFormData(boundary: "B")
    form.append("value", name: "field\"name")

    let bodyString = String(decoding: form.encode().body, as: UTF8.self)

    XCTAssertTrue(bodyString.contains("name=\"field\\\"name\""))
  }
}
