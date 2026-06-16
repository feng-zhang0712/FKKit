import FKCoreKit
import XCTest

final class URLExtensionTests: XCTestCase {
  func testQueryParametersParsesAndKeepsLastDuplicateValue() {
    let url = URL(string: "https://example.com/path?ref=home&ref=push&tab=1")!

    XCTAssertEqual(url.fk_queryParameters["ref"], "push")
    XCTAssertEqual(url.fk_queryParameters["tab"], "1")
  }

  func testAppendingQueryParametersReplacesExistingNames() {
    let original = URL(string: "https://example.com/items?sort=asc")!
    let updated = original.fk_appendingQueryParameters(["sort": "desc", "page": "2"])

    XCTAssertEqual(updated.fk_queryParameters["sort"], "desc")
    XCTAssertEqual(updated.fk_queryParameters["page"], "2")
  }

  func testRemovingQueryParametersDropsNamedKeys() {
    let original = URL(string: "https://example.com/items?sort=asc&page=2")!
    let updated = original.fk_removingQueryParameters(named: ["page"])

    XCTAssertEqual(updated.fk_queryParameters["sort"], "asc")
    XCTAssertNil(updated.fk_queryParameters["page"])
  }

  func testIsHTTPOrHTTPSDetectsWebSchemesOnly() {
    XCTAssertTrue(URL(string: "https://example.com")!.fk_isHTTPOrHTTPS)
    XCTAssertTrue(URL(string: "http://example.com")!.fk_isHTTPOrHTTPS)
    XCTAssertFalse(URL(string: "myapp://host/path")!.fk_isHTTPOrHTTPS)
  }
}
