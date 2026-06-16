import FKCoreKit
import XCTest

private struct StoredSettings: Codable, Equatable {
  let enabled: Bool
  let count: Int
}

final class UserDefaultsExtensionTests: XCTestCase {
  private let defaults = UserDefaults(suiteName: "com.fkkit.tests.userdefaults")!
  private let key = "fkkit.test.settings"

  override func tearDown() {
    defaults.fk_removeValue(forKey: key)
    super.tearDown()
  }

  func testEncodeAndDecodeJSONRoundTripsCodableValue() throws {
    let expected = StoredSettings(enabled: true, count: 3)

    try defaults.fk_encodeJSON(expected, forKey: key)
    let decoded = try defaults.fk_decodeJSON(StoredSettings.self, forKey: key)

    XCTAssertEqual(decoded, expected)
  }

  func testDecodeJSONReturnsNilWhenKeyIsMissing() throws {
    let decoded = try defaults.fk_decodeJSON(StoredSettings.self, forKey: "missing.key")

    XCTAssertNil(decoded)
  }
}
