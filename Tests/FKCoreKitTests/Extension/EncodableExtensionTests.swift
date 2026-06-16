import FKCoreKit
import XCTest

private struct SampleModel: Codable, Equatable {
  let id: Int
  let label: String
}

final class EncodableExtensionTests: XCTestCase {
  func testJSONDataEncodesModelToUTF8JSON() throws {
    let model = SampleModel(id: 1, label: "alpha")
    let data = try model.fk_jsonData()

    XCTAssertFalse(data.isEmpty)
    XCTAssertNotNil(data.fk_utf8String)
  }

  func testJSONStringRoundTripsThroughDecodedHelper() throws {
    let model = SampleModel(id: 7, label: "beta")
    let json = try model.fk_jsonString()
    let decoded = try SampleModel.fk_decoded(from: json)

    XCTAssertEqual(decoded, model)
  }

  func testDecodedFromDataThrowsWhenPayloadIsInvalid() {
    XCTAssertThrowsError(try SampleModel.fk_decoded(from: Data("{".utf8)))
  }
}
