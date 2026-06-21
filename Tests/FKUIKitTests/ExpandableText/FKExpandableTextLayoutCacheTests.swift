@testable import FKUIKit
import XCTest

@MainActor
final class FKExpandableTextLayoutCacheTests: XCTestCase {
  func testSetAndGetValueRoundTrip() {
    let cache = FKExpandableTextLayoutCache.shared
    let key = "test-key-\(UUID().uuidString)"
    let value = NSAttributedString(string: "Cached copy")

    cache.setValue(value, forKey: key)

    XCTAssertEqual(cache.value(forKey: key)?.string, "Cached copy")
  }

  func testMakeKeyChangesWhenWidthChanges() {
    let text = NSAttributedString(string: "Body")
    let action = NSAttributedString(string: "More")
    let token = NSAttributedString(string: "...")

    let narrow = cacheKey(width: 100, text: text, action: action, token: token)
    let wide = cacheKey(width: 200, text: text, action: action, token: token)

    XCTAssertNotEqual(narrow, wide)
  }

  func testMakeKeyChangesWhenButtonPlacementChanges() {
    let text = NSAttributedString(string: "Body")
    let action = NSAttributedString(string: "More")
    let token = NSAttributedString(string: "...")

    let inline = cacheKey(
      width: 120,
      text: text,
      action: action,
      token: token,
      placement: .inlineTail
    )
    let below = cacheKey(
      width: 120,
      text: text,
      action: action,
      token: token,
      placement: .trailingBottom
    )

    XCTAssertNotEqual(inline, below)
  }

  func testMakeKeyIsStableForSameInputs() {
    let text = NSAttributedString(string: "Stable")
    let action = NSAttributedString(string: "More")
    let token = NSAttributedString(string: "...")

    let first = cacheKey(width: 150, text: text, action: action, token: token)
    let second = cacheKey(width: 150, text: text, action: action, token: token)

    XCTAssertEqual(first, second)
  }

  private func cacheKey(
    width: CGFloat,
    text: NSAttributedString,
    action: NSAttributedString,
    token: NSAttributedString,
    placement: FKExpandableTextConfiguration.ButtonPlacement = .inlineTail
  ) -> String {
    FKExpandableTextLayoutCache.shared.makeKey(
      text: text,
      width: width,
      numberOfLines: 3,
      lineBreakMode: .byTruncatingTail,
      placement: placement,
      actionText: action,
      token: token
    )
  }
}
