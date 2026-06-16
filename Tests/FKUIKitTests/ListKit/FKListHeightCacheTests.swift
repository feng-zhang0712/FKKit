import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKListHeightCacheTests: FKUIKitTestCase {
  private var cache: FKListHeightCache!

  override func setUp() {
    super.setUp()
    cache = FKListHeightCache()
  }

  override func tearDown() {
    cache = nil
    super.tearDown()
  }

  func testSetAndHeightRoundTripForMatchingWidth() {
    cache.setHeight(88, for: "row-1", width: 320)
    XCTAssertEqual(cache.height(for: "row-1", width: 320), 88)
  }

  func testInvalidateRemovesCachedHeightsForItem() {
    cache.setHeight(88, for: "row-1", width: 320)
    cache.invalidate(itemID: "row-1")
    XCTAssertNil(cache.height(for: "row-1", width: 320))
  }

  func testInvalidateAllClearsEveryEntry() {
    cache.setHeight(44, for: "a", width: 300)
    cache.setHeight(55, for: "b", width: 300)
    cache.invalidateAll()

    XCTAssertNil(cache.height(for: "a", width: 300))
    XCTAssertNil(cache.height(for: "b", width: 300))
  }

  func testMeasuredTextHeightReturnsInsetsOnlyForEmptyText() {
    let height = FKListHeightCache.measuredTextHeight(
      "",
      font: .systemFont(ofSize: 16),
      width: 200,
      insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    )
    XCTAssertEqual(height, 16, accuracy: 0.01)
  }

  func testMeasuredTextHeightIncreasesWithLongerText() {
    let font = UIFont.systemFont(ofSize: 16)
    let short = FKListHeightCache.measuredTextHeight("Hi", font: font, width: 200)
    let long = FKListHeightCache.measuredTextHeight(
      String(repeating: "Word ", count: 20),
      font: font,
      width: 200
    )
    XCTAssertGreaterThan(long, short)
  }
}
