import FKUIKit
import XCTest

final class FKListLayoutConfigurationTests: XCTestCase {
  func testInitClampsEstimatedHeightsToAtLeastOnePoint() {
    let configuration = FKListLayoutConfiguration(
      estimatedRowHeight: 0,
      estimatedCollectionItemHeight: -10
    )

    XCTAssertEqual(configuration.estimatedRowHeight, 1, accuracy: 0.001)
    XCTAssertEqual(configuration.estimatedCollectionItemHeight, 1, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesAutomaticRowHeightAndPinnedHeaders() {
    let configuration = FKListLayoutConfiguration()

    XCTAssertEqual(configuration.rowHeightPolicy, .automatic)
    XCTAssertTrue(configuration.pinsSectionHeaders)
    if case .fkDivider(let leadingInset) = configuration.separatorMode {
      XCTAssertEqual(leadingInset, 16, accuracy: 0.001)
    } else {
      XCTFail("Expected fkDivider separator mode")
    }
  }
}
