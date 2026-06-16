import FKCoreKit
import XCTest

final class FKBusinessDeeplinkRouterTests: XCTestCase {
  private var router: FKBusinessDeeplinkRouter!

  override func setUp() {
    super.setUp()
    router = FKBusinessDeeplinkRouter()
  }

  override func tearDown() {
    router = nil
    super.tearDown()
  }

  func testRouteMatchesWildcardPathPattern() {
    let expectation = expectation(description: "handler invoked")
    router.register(
      FKDeeplinkRoute(id: "product", pathPattern: "/product/*") { context in
        XCTAssertEqual(context.parameters["ref"], "home")
        expectation.fulfill()
        return true
      }
    )

    let url = URL(string: "myapp://any/product/12847?ref=home")!
    XCTAssertTrue(router.route(url, source: .deeplink))

    wait(for: [expectation], timeout: 1)
  }

  func testRouteReturnsFalseWhenNoPatternMatches() {
    router.register(
      FKDeeplinkRoute(id: "settings", pathPattern: "/settings") { _ in true }
    )

    let url = URL(string: "myapp://host/profile")!
    XCTAssertFalse(router.route(url, source: .deeplink))
  }

  func testUnregisterRemovesRoute() {
    router.register(FKDeeplinkRoute(id: "help", pathPattern: "/help") { _ in true })
    router.unregister("help")

    let url = URL(string: "myapp://host/help")!
    XCTAssertFalse(router.route(url, source: .deeplink))
  }

  func testFirstMatchingHandlerReturningTrueWins() {
    router.register(FKDeeplinkRoute(id: "first", pathPattern: "/item/*") { _ in false })
    router.register(FKDeeplinkRoute(id: "second", pathPattern: "/item/*") { _ in true })

    let url = URL(string: "myapp://host/item/1")!
    XCTAssertTrue(router.route(url, source: .universalLink))
  }
}
