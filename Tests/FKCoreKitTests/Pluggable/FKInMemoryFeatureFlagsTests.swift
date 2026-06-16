import FKCoreKit
import XCTest

final class FKInMemoryFeatureFlagsTests: XCTestCase {
  func testIsEnabledReturnsDefaultAndFallsBackToFalseForUnknownKeys() {
    let flags = FKInMemoryFeatureFlags(defaults: ["checkout.v2": true])

    XCTAssertTrue(flags.isEnabled("checkout.v2"))
    XCTAssertFalse(flags.isEnabled("unknown.flag"))
  }

  func testSetEnabledOverridesBooleanFlagAtRuntime() {
    let flags = FKInMemoryFeatureFlags(defaults: ["feature.a": false])

    flags.setEnabled(true, forKey: "feature.a")

    XCTAssertTrue(flags.isEnabled("feature.a"))
  }

  func testStringValueReturnsDefaultAndSupportsRuntimeOverride() {
    let flags = FKInMemoryFeatureFlags(stringDefaults: ["theme.variant": "dark"])

    XCTAssertEqual(flags.stringValue(for: "theme.variant"), "dark")
    XCTAssertNil(flags.stringValue(for: "missing.key"))

    flags.setStringValue("light", forKey: "theme.variant")
    XCTAssertEqual(flags.stringValue(for: "theme.variant"), "light")

    flags.setStringValue(nil, forKey: "theme.variant")
    XCTAssertNil(flags.stringValue(for: "theme.variant"))
  }
}
