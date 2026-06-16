import FKCoreKit
import XCTest

final class FKRouteContextURLTests: XCTestCase {
  func testFromURLParsesPathComponentsAndQueryItems() {
    let url = URL(string: "myapp://host/settings/profile?tab=security&ref=home")!
    let context = FKRouteContext.from(url: url)

    XCTAssertEqual(context.url, url)
    XCTAssertEqual(context.pathComponents, ["settings", "profile"])
    XCTAssertEqual(context.queryItems["tab"], "security")
    XCTAssertEqual(context.queryItems["ref"], "home")
  }

  func testFromURLHandlesRootPathWithoutSegments() {
    let url = URL(string: "myapp://host/?source=push")!
    let context = FKRouteContext.from(url: url)

    XCTAssertTrue(context.pathComponents.isEmpty)
    XCTAssertEqual(context.queryItems["source"], "push")
  }
}
