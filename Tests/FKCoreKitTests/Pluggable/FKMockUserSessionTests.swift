import FKCoreKit
import XCTest

final class FKMockUserSessionTests: XCTestCase {
  func testSignInUpdatesAuthenticationStateAndNotifiesObserver() {
    let session = FKMockUserSession()
    let counter = LockedCounter()

    let token = session.observeAuthenticationChange { isAuthenticated in
      if isAuthenticated {
        counter.increment()
      }
    }
    defer { token.cancel() }

    session.signIn(userID: "user-42")

    XCTAssertTrue(session.isAuthenticated)
    XCTAssertEqual(session.userID, "user-42")
    XCTAssertEqual(counter.current, 1)
  }

  func testSignOutClearsSessionAndNotifiesObserver() throws {
    let session = FKMockUserSession()
    session.signIn(userID: "user-42")

    let counter = LockedCounter()
    let token = session.observeAuthenticationChange { isAuthenticated in
      if !isAuthenticated {
        counter.increment()
      }
    }
    defer { token.cancel() }

    try session.signOut()

    XCTAssertFalse(session.isAuthenticated)
    XCTAssertNil(session.userID)
    XCTAssertEqual(counter.current, 1)
  }
}
