import FKUIKit
import XCTest

final class FKListPresentationStateTests: XCTestCase {
  func testPresentationStateEquatableAcrossCases() {
    XCTAssertEqual(FKListPresentationState.initialLoading, .initialLoading)
    XCTAssertEqual(FKListPresentationState.content, .content)
    XCTAssertEqual(FKListPresentationState.empty, .empty)
    XCTAssertEqual(FKListPresentationState.refreshing, .refreshing)
    XCTAssertEqual(FKListPresentationState.loadingNextPage, .loadingNextPage)

    let errorA = FKListPresentationState.error(
      FKListErrorPresentation(title: "Failed", message: "Try again")
    )
    let errorB = FKListPresentationState.error(
      FKListErrorPresentation(title: "Failed", message: "Try again")
    )
    XCTAssertEqual(errorA, errorB)
    XCTAssertNotEqual(errorA, .content)
  }

  func testErrorPresentationStoresOptionalDebugDescription() {
    let presentation = FKListErrorPresentation(
      title: "Network",
      message: "Offline",
      debugDescription: "NSURLErrorNotConnectedToInternet"
    )

    XCTAssertEqual(presentation.title, "Network")
    XCTAssertEqual(presentation.message, "Offline")
    XCTAssertEqual(presentation.debugDescription, "NSURLErrorNotConnectedToInternet")
  }
}
