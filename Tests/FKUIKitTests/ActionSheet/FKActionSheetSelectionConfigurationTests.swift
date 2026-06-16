import FKUIKit
import XCTest

final class FKActionSheetSelectionConfigurationTests: XCTestCase {
  func testSelectedCountReflectsSingleAndMultipleModes() {
    let singleID = UUID()
    var single = FKActionSheetSelectionConfiguration(
      mode: .single(scope: .allSections),
      selectedActionID: singleID
    )
    XCTAssertEqual(single.selectedCount, 1)

    let first = UUID()
    let second = UUID()
    var multiple = FKActionSheetSelectionConfiguration(
      mode: .multiple(.init(maxSelectionCount: 5)),
      selectedActionIDs: [first, second]
    )
    XCTAssertEqual(multiple.selectedCount, 2)

    single.selectedActionID = nil
    multiple.selectedActionIDs = []
    XCTAssertEqual(single.selectedCount, 0)
    XCTAssertEqual(multiple.selectedCount, 0)
  }

  func testMultipleSelectionClampsNegativeMaxSelectionCountToZero() {
    let selection = FKActionSheetSelectionConfiguration.MultipleSelection(maxSelectionCount: -3)
    XCTAssertEqual(selection.maxSelectionCount, 0)
  }

  func testNoneModeReportsZeroSelectedCount() {
    let configuration = FKActionSheetSelectionConfiguration(mode: .none)
    XCTAssertEqual(configuration.selectedCount, 0)
  }
}
