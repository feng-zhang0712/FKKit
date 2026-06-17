import FKUIKit
import XCTest

@MainActor
final class FKCalloutPresentationTests: FKUIKitTestCase {
  private var window: UIWindow!
  private var host: UIViewController!
  private var anchor: UIView!

  override func setUp() {
    super.setUp()
    FKCallout.dismissActive(animated: false)

    host = UIViewController()
    host.view.frame = CGRect(x: 0, y: 0, width: 320, height: 568)
    anchor = UIView(frame: CGRect(x: 120, y: 220, width: 80, height: 40))
    host.view.addSubview(anchor)

    window = UIWindow(frame: host.view.bounds)
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.layoutIfNeeded()
  }

  override func tearDown() {
    FKCallout.dismissActive(animated: false)
    window.isHidden = true
    window = nil
    host = nil
    anchor = nil
    super.tearDown()
  }

  func testShowReturnsHandleWhenAnchorIsInWindow() {
    var configuration = FKCalloutConfiguration.tooltipDefault()
    configuration.animationDuration = 0

    let handle = FKCallout.show(
      content: .message("Tooltip"),
      anchoredTo: anchor,
      configuration: configuration
    )

    XCTAssertNotNil(handle)
    XCTAssertTrue(FKCallout.isPresenting)
  }

  func testDismissClearsPresentingState() {
    var configuration = FKCalloutConfiguration.tooltipDefault()
    configuration.animationDuration = 0

    let handle = FKCallout.show(
      content: .message("Tooltip"),
      anchoredTo: anchor,
      configuration: configuration
    )
    XCTAssertNotNil(handle)

    FKCallout.dismiss(handle!.id, animated: false)

    XCTAssertFalse(FKCallout.isPresenting)
  }

  func testShowReturnsNilWhenAnchorIsNotInWindowHierarchy() {
    let orphan = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

    let handle = FKCallout.show(
      content: .message("Orphan"),
      anchoredTo: orphan,
      configuration: FKCalloutConfiguration.tooltipDefault()
    )

    XCTAssertNil(handle)
    XCTAssertFalse(FKCallout.isPresenting)
  }
}
