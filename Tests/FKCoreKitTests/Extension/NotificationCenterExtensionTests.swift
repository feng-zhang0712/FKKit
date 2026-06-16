import FKCoreKit
import XCTest

final class NotificationCenterExtensionTests: XCTestCase {
  func testPostOnMainDeliversNotificationToObserver() {
    let center = NotificationCenter()
    let name = Notification.Name("fk.test.notificationCenter.postOnMain")
    let expectation = expectation(description: "notification received")
    let token = center.addObserver(forName: name, object: nil, queue: nil) { _ in
      expectation.fulfill()
    }
    defer { center.removeObserver(token) }

    center.fk_postOnMain(name: name, object: nil, userInfo: ["key": "value"])
    wait(for: [expectation], timeout: 1)
  }

  func testPostOnMainConvenienceWrapsNameAndUserInfo() {
    let center = NotificationCenter()
    let name = Notification.Name("fk.test.notificationCenter.userInfo")
    let expectation = expectation(description: "userInfo delivered")
    let token = center.addObserver(forName: name, object: nil, queue: nil) { notification in
      XCTAssertEqual(notification.userInfo?["token"] as? String, "abc")
      expectation.fulfill()
    }
    defer { center.removeObserver(token) }

    center.fk_postOnMain(name: name, userInfo: ["token": "abc"])
    wait(for: [expectation], timeout: 1)
  }
}
