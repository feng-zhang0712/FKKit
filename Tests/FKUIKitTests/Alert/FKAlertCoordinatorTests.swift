@testable import FKUIKit
import FKCoreKit
import XCTest

@MainActor
final class FKAlertCoordinatorTests: FKUIKitTestCase {
  private var window: UIWindow!
  private var host: UIViewController!

  override func setUp() {
    super.setUp()
    host = UIViewController()
    window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
    window.rootViewController = host
    window.makeKeyAndVisible()
  }

  override func tearDown() {
    window.isHidden = true
    window = nil
    host = nil
    super.tearDown()
  }

  func testReturnsDismissedWhenPresenterCannotBeResolved() async {
    let coordinator = FKAlertCoordinator()
    let content = FKAlertContent(title: "Title", message: "Message")

    let result = await coordinator.present(
      content: content,
      from: nil,
      configuration: .init(),
      presenterDelegate: nil,
      allowsDuplicateByID: false
    )

    XCTAssertEqual(result, .dismissed)
    XCTAssertFalse(coordinator.isPresenting)
  }

  func testPresentOnceByIDSkipsDuplicateWhileFirstAlertIsActive() async throws {
    let coordinator = FKAlertCoordinator()
    var configuration = FKAlertConfiguration()
    configuration.queue = .presentOnceByID
    let content = FKAlertContent(
      id: "duplicate-alert",
      title: "Title",
      message: "Message",
      actions: [FKAlertAction(title: "OK", style: .default)]
    )

    let firstTask = Task { @MainActor in
      await coordinator.present(
        content: content,
        from: host,
        configuration: configuration,
        presenterDelegate: nil,
        allowsDuplicateByID: false
      )
    }

    try await waitUntil(timeout: 2) { coordinator.isPresenting }

    let duplicate = await coordinator.present(
      content: content,
      from: host,
      configuration: configuration,
      presenterDelegate: nil,
      allowsDuplicateByID: false
    )
    XCTAssertNil(duplicate)

    coordinator.dismissActive(animated: false, result: .dismissed, invokeHandlers: false)
    _ = await firstTask.value
  }

  private func waitUntil(
    timeout: TimeInterval = 2,
    pollIntervalNanoseconds: UInt64 = 20_000_000,
    _ predicate: @escaping @MainActor () -> Bool
  ) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while await predicate() == false {
      if Date() > deadline {
        throw NSError(domain: "FKAlertCoordinatorTests", code: 1)
      }
      try await Task.sleep(nanoseconds: pollIntervalNanoseconds)
    }
  }
}
