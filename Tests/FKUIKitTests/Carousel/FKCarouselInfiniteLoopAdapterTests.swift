@testable import FKUIKit
import XCTest

final class FKCarouselInfiniteLoopAdapterTests: XCTestCase {
  func testPhysicalCountAddsBoundaryPagesWhenLoopingIsActive() {
    let adapter = FKCarouselInfiniteLoopAdapter(isEnabled: true, logicalCount: 3)

    XCTAssertTrue(adapter.isActive)
    XCTAssertEqual(adapter.physicalCount, 5)
  }

  func testLogicalIndexMapsBoundaryPhysicalPages() {
    let adapter = FKCarouselInfiniteLoopAdapter(isEnabled: true, logicalCount: 3)

    XCTAssertEqual(adapter.logicalIndex(forPhysical: 0), 2)
    XCTAssertEqual(adapter.logicalIndex(forPhysical: 4), 0)
    XCTAssertEqual(adapter.logicalIndex(forPhysical: 2), 1)
  }

  func testLoopCorrectionTargetsInnerDuplicatePages() {
    let adapter = FKCarouselInfiniteLoopAdapter(isEnabled: true, logicalCount: 3)

    XCTAssertEqual(adapter.loopCorrection(physicalIndex: 0)?.targetPhysicalIndex, 3)
    XCTAssertEqual(adapter.loopCorrection(physicalIndex: 4)?.targetPhysicalIndex, 1)
    XCTAssertNil(adapter.loopCorrection(physicalIndex: 2))
  }

  func testAdapterIsInactiveForSingleItemCarousel() {
    let adapter = FKCarouselInfiniteLoopAdapter(isEnabled: true, logicalCount: 1)

    XCTAssertFalse(adapter.isActive)
    XCTAssertEqual(adapter.physicalCount, 1)
    XCTAssertEqual(adapter.physicalIndex(forLogical: 0), 0)
  }
}
