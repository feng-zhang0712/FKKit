@testable import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKSheetPresentationLayoutEngineTests: FKUIKitTestCase {
  private func makeEnvironment(
    configuration: FKSheetPresentationConfiguration = .bottomSheetDefault,
    bounds: CGRect = CGRect(x: 0, y: 0, width: 390, height: 844),
    safeArea: UIEdgeInsets = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
    preferredContentSize: CGSize = .zero
  ) -> FKSheetPresentationLayoutEngine.Environment {
    FKSheetPresentationLayoutEngine.Environment(
      configuration: configuration,
      containerBounds: bounds,
      containerSafeAreaInsets: safeArea,
      preferredContentSize: preferredContentSize,
      contentViewForFitting: nil
    )
  }

  func testAvailableHeightSubtractsSafeAreaWhenContainerRespectsSafeArea() {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.safeAreaPolicy = .containerRespectsSafeArea
    let environment = makeEnvironment(configuration: configuration)

    let available = FKSheetPresentationLayoutEngine.availableHeight(for: environment)

    XCTAssertEqual(available, 844 - 47 - 34, accuracy: 0.001)
  }

  func testAvailableHeightIgnoresSafeAreaForContentRespectsSafeAreaPolicy() {
    let environment = makeEnvironment()

    let available = FKSheetPresentationLayoutEngine.availableHeight(for: environment)

    XCTAssertEqual(available, 844, accuracy: 0.001)
  }

  func testResolveFixedDetentClampsToAvailableHeight() {
    let environment = makeEnvironment()

    let height = FKSheetPresentationLayoutEngine.resolve(
      detent: .fixed(900),
      availableHeight: 700,
      environment: environment
    )

    XCTAssertEqual(height, 700, accuracy: 0.001)
  }

  func testResolveFractionDetentUsesAvailableHeight() {
    let environment = makeEnvironment()

    let height = FKSheetPresentationLayoutEngine.resolve(
      detent: .fraction(0.5),
      availableHeight: 800,
      environment: environment
    )

    XCTAssertEqual(height, 400, accuracy: 0.001)
  }

  func testResolveMediumDetentUsesHalfOfAvailableHeight() {
    let environment = makeEnvironment()

    let height = FKSheetPresentationLayoutEngine.resolve(
      detent: .medium,
      availableHeight: 600,
      environment: environment
    )

    XCTAssertEqual(height, 300, accuracy: 0.001)
  }

  func testRecalculateDetentsClampsSelectedIndex() {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.applyingSheet { $0.detents = [.fixed(200), .fixed(400)] }
    let environment = makeEnvironment(configuration: configuration)

    let state = FKSheetPresentationLayoutEngine.recalculateDetents(
      environment: environment,
      selectedIndex: 9
    )

    XCTAssertEqual(state.selectedIndex, 1)
    XCTAssertEqual(state.resolvedHeights.count, 2)
  }

  func testResolvedSheetWidthFillUsesContainerWidth() {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.sheet.widthPolicy = .fill
    let environment = makeEnvironment(configuration: configuration)

    XCTAssertEqual(
      FKSheetPresentationLayoutEngine.resolvedSheetWidth(environment: environment),
      390,
      accuracy: 0.001
    )
  }

  func testEdgeFrameAnchorsLeftSheetToLeadingEdge() {
    let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)

    let frame = FKSheetPresentationLayoutEngine.edgeFrame(in: bounds, edge: .left)

    XCTAssertEqual(frame.origin.x, 0, accuracy: 0.001)
    XCTAssertEqual(frame.height, bounds.height, accuracy: 0.001)
    XCTAssertLessThanOrEqual(frame.width, 420)
  }
}
