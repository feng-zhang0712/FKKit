import FKUIKit
import XCTest

final class FKSearchPresentationStateTests: XCTestCase {
  func testEquatableCasesMatchAssociatedValues() {
    XCTAssertEqual(FKSearchPresentationState.idle, .idle)
    XCTAssertEqual(FKSearchPresentationState.editing, .editing)
    XCTAssertEqual(FKSearchPresentationState.loading(query: "cat"), .loading(query: "cat"))
    XCTAssertEqual(
      FKSearchPresentationState.results(query: "cat", itemCount: 3),
      .results(query: "cat", itemCount: 3)
    )
    XCTAssertEqual(
      FKSearchPresentationState.empty(query: "cat", scenario: .noSearchResult),
      .empty(query: "cat", scenario: .noSearchResult)
    )
    XCTAssertEqual(
      FKSearchPresentationState.error(query: "cat", error: .cancelled),
      .error(query: "cat", error: .cancelled)
    )
  }

  func testResultsStatePreservesItemCount() {
    let state = FKSearchPresentationState.results(query: "swift", itemCount: 12)
    guard case let .results(query, itemCount) = state else {
      XCTFail("Expected results state")
      return
    }
    XCTAssertEqual(query, "swift")
    XCTAssertEqual(itemCount, 12)
  }
}
