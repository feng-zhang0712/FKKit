import FKUIKit
import XCTest

final class FKSearchPresentationConfigurationTests: XCTestCase {
  func testUnifiedPresetUsesEmbeddedListAndListSnapshotIdle() {
    let configuration = FKSearchPresentationConfiguration.unified

    XCTAssertEqual(configuration.resultsMode, .embeddedList)
    XCTAssertEqual(configuration.idleContent, .listSnapshot)
  }

  func testCustomIdleHostHandledResultsUsesHostHandledMode() {
    let configuration = FKSearchPresentationConfiguration.customIdleHostHandledResults

    XCTAssertEqual(configuration.resultsMode, .hostHandled)
    XCTAssertEqual(configuration.idleContent, .customViewController)
  }

  func testCustomResultsViewControllerUsesCustomResultsSurface() {
    let configuration = FKSearchPresentationConfiguration.customResultsViewController

    XCTAssertEqual(configuration.resultsMode, .customViewController)
    XCTAssertEqual(configuration.idleContent, .listSnapshot)
  }
}
