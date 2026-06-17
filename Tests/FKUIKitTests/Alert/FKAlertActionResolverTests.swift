@testable import FKUIKit
import FKCoreKit
import XCTest

final class FKAlertActionResolverTests: XCTestCase {
  func testNormalizedActionsInsertsDefaultOKWhenEmpty() {
    let content = FKAlertContent(title: "Title", message: "Message", actions: [])

    let actions = FKAlertActionResolver.normalizedActions(for: content)

    XCTAssertEqual(actions.count, 1)
    XCTAssertEqual(actions[0].style, .default)
  }

  func testResolvedActionsOrdersPrimaryDestructiveThenCancel() {
    let actions = [
      FKAlertAction(title: "Delete", style: .destructive),
      FKAlertAction(title: "OK", style: .default),
      FKAlertAction(title: "Cancel", style: .cancel),
    ]

    let resolved = FKAlertActionResolver.resolvedActions(from: actions)

    XCTAssertEqual(resolved.map(\.action.title), ["OK", "Delete", "Cancel"])
    XCTAssertEqual(resolved.map(\.role), [.primary, .destructive, .cancel])
    XCTAssertEqual(resolved.map(\.sourceIndex), [1, 0, 2])
  }

  func testNormalizedActionsPreservesThreeOrFewerActions() {
    let actions = [
      FKAlertAction(title: "OK", style: .default),
      FKAlertAction(title: "Delete", style: .destructive),
      FKAlertAction(title: "Cancel", style: .cancel),
    ]
    let content = FKAlertContent(title: "Title", message: "Message", actions: actions)

    let normalized = FKAlertActionResolver.normalizedActions(for: content)

    XCTAssertEqual(normalized.map(\.title), actions.map(\.title))
    XCTAssertEqual(normalized.map(\.style), actions.map(\.style))
  }

  func testResolvedAttributedMessageReturnsNilForEmptyArchive() {
    let empty = NSAttributedString(string: "")
    let data = FKAlertContent.archiveAttributedMessage(empty)

    XCTAssertNil(FKAlertActionResolver.resolvedAttributedMessage(from: data))
  }

  func testResolvedAttributedMessageRoundTripsNonEmptyArchive() {
    let message = NSAttributedString(string: "Rich text")
    let data = FKAlertContent.archiveAttributedMessage(message)

    XCTAssertEqual(FKAlertActionResolver.resolvedAttributedMessage(from: data)?.string, "Rich text")
  }
}
