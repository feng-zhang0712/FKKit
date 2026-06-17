@testable import FKCoreKit
import UIKit
import XCTest

#if os(iOS)
@MainActor
final class FKPermissionPrePromptPresenterTests: XCTestCase {
  private var window: UIWindow!
  private var host: UIViewController!

  override func setUp() async throws {
    try await super.setUp()
    host = UIViewController()
    window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
    host.loadViewIfNeeded()
    window.rootViewController = host
    window.makeKeyAndVisible()
  }

  override func tearDown() async throws {
    if let presented = host?.presentedViewController {
      presented.dismiss(animated: false)
    }
    window?.isHidden = true
    window = nil
    host = nil
    try await super.tearDown()
  }

  func testPresentIfNeededReturnsTrueWhenPrePromptIsNil() async {
    let presenter = FKPermissionPrePromptPresenter()

    let shouldContinue = await presenter.presentIfNeeded(nil, from: host)

    XCTAssertTrue(shouldContinue)
  }

  func testPresentIfNeededReturnsFalseWhenUserDeclines() async {
    let presenter = FKPermissionPrePromptPresenter { _, _, completion in
      completion(false)
    }
    let prePrompt = FKPermissionPrePrompt(
      title: "Camera",
      message: "We need camera access.",
      confirmTitle: "Continue",
      cancelTitle: "Not now"
    )

    let shouldContinue = await presenter.presentIfNeeded(prePrompt, from: host)

    XCTAssertFalse(shouldContinue)
  }

  func testPresentIfNeededReturnsTrueWhenUserConfirms() async {
    let presenter = FKPermissionPrePromptPresenter { _, _, completion in
      completion(true)
    }
    let prePrompt = FKPermissionPrePrompt(
      title: "Camera",
      message: "We need camera access.",
      confirmTitle: "Continue",
      cancelTitle: "Not now"
    )

    let shouldContinue = await presenter.presentIfNeeded(prePrompt, from: host)

    XCTAssertTrue(shouldContinue)
  }

  func testMakePrePromptAlertUsesConfiguredTitles() {
    let prePrompt = FKPermissionPrePrompt(
      title: "Camera",
      message: "We need camera access.",
      confirmTitle: "Continue",
      cancelTitle: "Not now"
    )

    let alert = FKPermissionPrePromptPresenter.makePrePromptAlert(prePrompt: prePrompt) { _ in }

    XCTAssertEqual(alert.title, prePrompt.title)
    XCTAssertEqual(alert.message, prePrompt.message)
    XCTAssertEqual(alert.actions.map(\.title), [prePrompt.cancelTitle, prePrompt.confirmTitle])
  }

  func testRequestReturnsPrePromptCancelledWhenUserDeclinesPrePrompt() async {
    let prePrompt = FKPermissionPrePrompt(
      title: "Microphone",
      message: "We need microphone access.",
      confirmTitle: "Continue",
      cancelTitle: "Not now"
    )
    let request = FKPermissionRequest(kind: .microphone, prePrompt: prePrompt)
    let permissions = FKPermissions(
      prePromptPresenter: FKPermissionPrePromptPresenter { _, _, completion in
        completion(false)
      }
    )

    let result = await permissions.request(request, presentingFrom: host)

    XCTAssertEqual(result.error, FKPermissionError.prePromptCancelled)
    XCTAssertEqual(result.kind, FKPermissionKind.microphone)
  }
}
#endif
