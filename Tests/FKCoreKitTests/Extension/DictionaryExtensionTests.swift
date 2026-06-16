import FKCoreKit
import XCTest

private struct SamplePayload: Decodable, Equatable {
  let id: Int
  let name: String
}

final class DictionaryExtensionTests: XCTestCase {
  func testValueReturnsTypedValueWhenKeyMatches() {
    let dictionary: [String: Any] = ["count": 3, "label": "alpha"]

    XCTAssertEqual(dictionary.fk_value(for: "count", as: Int.self), 3)
    XCTAssertEqual(dictionary.fk_value(for: "label", as: String.self), "alpha")
    XCTAssertNil(dictionary.fk_value(for: "missing", as: String.self))
  }

  func testJSONStringEncodesDictionaryWhenValid() {
    let dictionary: [String: Any] = ["sort": "asc", "page": 2]

    let json = dictionary.fk_jsonString()

    XCTAssertNotNil(json)
    XCTAssertTrue(json!.contains("\"sort\""))
    XCTAssertTrue(json!.contains("\"page\""))
  }

  func testDecodeJSONBuildsDecodableModelFromDictionary() {
    let dictionary: [String: Any] = ["id": 42, "name": "widget"]
    let payload = dictionary.fk_decodeJSON(SamplePayload.self)

    XCTAssertEqual(payload, SamplePayload(id: 42, name: "widget"))
  }

  func testCompactValuesDropsNilEntries() {
    let dictionary: [String: Any?] = ["kept": "value", "dropped": nil, "count": 1]
    let compact = dictionary.fk_compactValues()

    XCTAssertEqual(compact["kept"] as? String, "value")
    XCTAssertEqual(compact["count"] as? Int, 1)
    XCTAssertNil(compact["dropped"])
  }
}
