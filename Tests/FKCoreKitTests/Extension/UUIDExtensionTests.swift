import FKCoreKit
import XCTest

final class UUIDExtensionTests: XCTestCase {
  func testCompactHexStringRoundTrip() {
    let original = UUID(uuidString: "8A4A6052-4A02-4E89-B7CB-0AC97097C13E")!
    let compact = original.fk_compactHexString
    XCTAssertEqual(compact, "8a4a60524a024e89b7cb0ac97097c13e")
    XCTAssertEqual(UUID(fk_hexString: compact), original)
  }

  func testHexStringInitializerRejectsInvalidInput() {
    XCTAssertNil(UUID(fk_hexString: "not-hex"))
    XCTAssertNil(UUID(fk_hexString: "abc"))
    XCTAssertNil(UUID(fk_hexString: "gggggggggggggggggggggggggggggggg"))
  }

  func testHexStringInitializerAcceptsUppercaseWithoutHyphens() {
    let uuid = UUID(fk_hexString: "8A4A60524A024E89B7CB0AC97097C13E")
    XCTAssertEqual(uuid, UUID(uuidString: "8A4A6052-4A02-4E89-B7CB-0AC97097C13E"))
  }
}
