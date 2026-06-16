import FKUIKit
import XCTest

final class FKSheetPresentationConfigurationTests: XCTestCase {
  func testEmptyDetentsFallbackToFitContent() {
    let sheet = FKSheetPresentationConfiguration.SheetConfiguration(detents: [])
    XCTAssertEqual(sheet.detents, [.fitContent])
  }

  func testInitialSelectedDetentIndexClampsToValidRange() {
    let sheet = FKSheetPresentationConfiguration.SheetConfiguration(
      detents: [.fitContent, .medium],
      initialSelectedDetentIndex: 99
    )
    XCTAssertEqual(sheet.initialSelectedDetentIndex, 1)
  }

  func testMultiStageBackdropClampsAlphaRange() {
    let backdrop = FKSheetPresentationConfiguration.SheetConfiguration.MultiStageBackdropConfiguration(
      minimumAlpha: -1,
      maximumAlpha: 2
    )
    XCTAssertEqual(backdrop.minimumAlpha, 0, accuracy: 0.001)
    XCTAssertEqual(backdrop.maximumAlpha, 1, accuracy: 0.001)
  }

  func testCenterConfigurationClampsDismissProgressThreshold() {
    let center = FKSheetPresentationConfiguration.CenterConfiguration(dismissProgressThreshold: 0)
    XCTAssertEqual(center.dismissProgressThreshold, 0.05, accuracy: 0.001)

    let high = FKSheetPresentationConfiguration.CenterConfiguration(dismissProgressThreshold: 2)
    XCTAssertEqual(high.dismissProgressThreshold, 0.95, accuracy: 0.001)
  }

  func testMaximumFitContentHeightFractionClampsIntoSupportedRange() {
    let sheet = FKSheetPresentationConfiguration.SheetConfiguration(maximumFitContentHeightFraction: 0.05)
    XCTAssertEqual(sheet.maximumFitContentHeightFraction, 0.2, accuracy: 0.001)

    let wide = FKSheetPresentationConfiguration.SheetConfiguration(maximumFitContentHeightFraction: 2)
    XCTAssertEqual(wide.maximumFitContentHeightFraction, 1, accuracy: 0.001)
  }
}
