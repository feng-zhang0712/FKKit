@testable import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKActionSheetLayoutTests: FKUIKitTestCase {
  private func makeSheet(configuration: FKActionSheetConfiguration) throws -> FKActionSheet {
    var configuration = configuration
    if configuration.sections.isEmpty {
      configuration.sections = [
        FKActionSheetSection(actions: [FKActionSheetAction(title: "OK")])
      ]
    }
    return try FKActionSheet(configuration: configuration)
  }

  func testContentLayoutWidthForBottomStyleClampsToMaxPanelWidth() throws {
    var configuration = FKActionSheetConfiguration()
    configuration.presentation.style = .bottom
    configuration.presentation.maxPanelWidth = 320
    configuration.presentation.horizontalInset = 16
    let sheet = try makeSheet(configuration: configuration)

    let width = sheet.contentLayoutWidth(for: 500)

    XCTAssertEqual(width, 320, accuracy: 0.001)
  }

  func testContentLayoutWidthForBottomStyleSubtractsHorizontalInset() throws {
    var configuration = FKActionSheetConfiguration()
    configuration.presentation.style = .bottom
    configuration.presentation.maxPanelWidth = 500
    configuration.presentation.horizontalInset = 20
    let sheet = try makeSheet(configuration: configuration)

    let width = sheet.contentLayoutWidth(for: 300)

    XCTAssertEqual(width, 260, accuracy: 0.001)
  }

  func testContentLayoutWidthForCenteredStyleMatchesBottomRules() throws {
    var configuration = FKActionSheetConfiguration()
    configuration.presentation = .centered
    configuration.presentation.maxPanelWidth = 400
    configuration.presentation.horizontalInset = 12
    let sheet = try makeSheet(configuration: configuration)

    let width = sheet.contentLayoutWidth(for: 360)

    XCTAssertEqual(width, 336, accuracy: 0.001)
  }

  func testContentLayoutWidthForPopoverUsesMinimumWhenViewWidthIsZero() throws {
    var configuration = FKActionSheetConfiguration()
    configuration.presentation = .popover
    configuration.presentation.popoverMinimumWidth = 280
    let sheet = try makeSheet(configuration: configuration)

    XCTAssertEqual(sheet.contentLayoutWidth(for: 0), 280, accuracy: 0.001)
  }

  func testContentLayoutWidthForPopoverUsesViewWidthWhenLargerThanMinimum() throws {
    var configuration = FKActionSheetConfiguration()
    configuration.presentation = .popover
    configuration.presentation.popoverMinimumWidth = 280
    let sheet = try makeSheet(configuration: configuration)

    XCTAssertEqual(sheet.contentLayoutWidth(for: 360), 360, accuracy: 0.001)
  }

  func testMaximumSheetHeightUsesConfiguredCap() throws {
    var configuration = FKActionSheetConfiguration()
    configuration.presentation.maximumFitContentHeightFraction = 0.5
    configuration.presentation.maximumPanelHeight = 300
    let sheet = try makeSheet(configuration: configuration)
    sheet.loadViewIfNeeded()
    sheet.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)

    XCTAssertEqual(sheet.maximumSheetHeight(), 300, accuracy: 0.001)
  }

  func testTableBottomContentInsetIsZeroForCenteredStyle() throws {
    var configuration = FKActionSheetConfiguration()
    configuration.presentation = .centered
    let sheet = try makeSheet(configuration: configuration)
    sheet.loadViewIfNeeded()

    XCTAssertEqual(sheet.tableBottomContentInset(), 0, accuracy: 0.001)
  }
}
