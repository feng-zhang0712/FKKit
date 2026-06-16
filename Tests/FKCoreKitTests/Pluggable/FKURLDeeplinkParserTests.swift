import FKCoreKit
import XCTest

final class FKURLDeeplinkParserTests: XCTestCase {
  private let parser = FKURLDeeplinkParser()

  func testParseReturnsRouteContextForCustomSchemeURL() {
    let url = URL(string: "myapp://host/catalog/item?color=red")!
    let context = parser.parse(url: url)

    XCTAssertNotNil(context)
    XCTAssertEqual(context?.pathComponents, ["catalog", "item"])
    XCTAssertEqual(context?.queryItems["color"], "red")
  }

  func testParseMatchesRouteContextFromURLForHTTPSLinks() {
    let url = URL(string: "https://example.com/docs/guide?lang=en")!
    let parsed = parser.parse(url: url)
    let expected = FKRouteContext.from(url: url)

    XCTAssertEqual(parsed?.url, expected.url)
    XCTAssertEqual(parsed?.pathComponents, expected.pathComponents)
    XCTAssertEqual(parsed?.queryItems, expected.queryItems)
  }
}
