@testable import FKUIKit
import UIKit
import XCTest

final class FKProgressBarLayoutEngineTests: XCTestCase {
  func testTrackRectInsetsBoundsByContentInsets() {
    let bounds = CGRect(x: 0, y: 0, width: 200, height: 20)
    let insets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)

    let track = FKProgressBarLayoutEngine.trackRect(in: bounds, contentInsets: insets)

    XCTAssertEqual(track, bounds.inset(by: insets))
  }

  func testLinearProgressFrameGrowsFromLeadingEdgeForHorizontalLTR() {
    let track = CGRect(x: 10, y: 0, width: 100, height: 8)

    let frame = FKProgressBarLayoutEngine.linearProgressFrame(
      track: track,
      fraction: 0.4,
      axis: .horizontal,
      layoutDirection: .leftToRight
    )

    XCTAssertEqual(frame.origin.x, 10, accuracy: 0.001)
    XCTAssertEqual(frame.width, 40, accuracy: 0.001)
    XCTAssertEqual(frame.height, 8, accuracy: 0.001)
  }

  func testLinearProgressFrameGrowsFromTrailingEdgeForHorizontalRTL() {
    let track = CGRect(x: 10, y: 0, width: 100, height: 8)

    let frame = FKProgressBarLayoutEngine.linearProgressFrame(
      track: track,
      fraction: 0.25,
      axis: .horizontal,
      layoutDirection: .rightToLeft
    )

    XCTAssertEqual(frame.maxX, track.maxX, accuracy: 0.001)
    XCTAssertEqual(frame.width, 25, accuracy: 0.001)
  }

  func testLinearProgressFrameGrowsFromBottomForVerticalAxis() {
    let track = CGRect(x: 0, y: 0, width: 8, height: 100)

    let frame = FKProgressBarLayoutEngine.linearProgressFrame(
      track: track,
      fraction: 0.5,
      axis: .vertical,
      layoutDirection: .leftToRight
    )

    XCTAssertEqual(frame.maxY, track.maxY, accuracy: 0.001)
    XCTAssertEqual(frame.height, 50, accuracy: 0.001)
  }

  func testLinearProgressFrameClampsFractionIntoZeroToOne() {
    let track = CGRect(x: 0, y: 0, width: 80, height: 8)

    let over = FKProgressBarLayoutEngine.linearProgressFrame(
      track: track,
      fraction: 2,
      axis: .horizontal,
      layoutDirection: .leftToRight
    )
    let under = FKProgressBarLayoutEngine.linearProgressFrame(
      track: track,
      fraction: -1,
      axis: .horizontal,
      layoutDirection: .leftToRight
    )

    XCTAssertEqual(over.width, track.width, accuracy: 0.001)
    XCTAssertEqual(under.width, 0, accuracy: 0.001)
  }

  func testRingLayoutCentersWithinRectAndRespectsLineWidth() {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
    let layout = FKProgressBarLayoutEngine.ringLayout(in: rect, lineWidth: 10)

    XCTAssertEqual(layout.center.x, 50, accuracy: 0.001)
    XCTAssertEqual(layout.center.y, 50, accuracy: 0.001)
    XCTAssertEqual(layout.radius, 45, accuracy: 0.001)
  }

  func testRingStartAngleBeginsAtTwelveOClock() {
    XCTAssertEqual(FKProgressBarLayoutEngine.ringStartAngle(), -.pi / 2, accuracy: 0.001)
  }

  func testSegmentParametersReturnsNilForSingleSegment() {
    let track = CGRect(x: 0, y: 0, width: 100, height: 8)

    let params = FKProgressBarLayoutEngine.segmentParameters(
      track: track,
      segmentCount: 1,
      gapFraction: 0.1,
      axis: .horizontal
    )

    XCTAssertNil(params)
  }

  func testSegmentParametersComputesCellSpanAndGapForHorizontalTrack() {
    let track = CGRect(x: 0, y: 0, width: 100, height: 8)

    let params = FKProgressBarLayoutEngine.segmentParameters(
      track: track,
      segmentCount: 4,
      gapFraction: 0.1,
      axis: .horizontal
    )

    XCTAssertEqual(params?.cellCount, 4)
    XCTAssertGreaterThan(params?.cellSpan ?? 0, 0)
    XCTAssertGreaterThan(params?.gap ?? 0, 0)
  }

  func testFilledSegmentIndexMapsProgressToSegmentCount() {
    XCTAssertEqual(FKProgressBarLayoutEngine.filledSegmentIndex(progress: 0.49, segmentCount: 4), 1)
    XCTAssertEqual(FKProgressBarLayoutEngine.filledSegmentIndex(progress: 1, segmentCount: 4), 4)
    XCTAssertEqual(FKProgressBarLayoutEngine.filledSegmentIndex(progress: 0.2, segmentCount: 0), 0)
  }

  func testLinearProgressFrameLocalOffsetsTrackOrigin() {
    let track = CGRect(x: 20, y: 10, width: 100, height: 8)

    let local = FKProgressBarLayoutEngine.linearProgressFrameLocal(
      track: track,
      fraction: 0.5,
      axis: .horizontal,
      layoutDirection: .leftToRight
    )

    XCTAssertEqual(local.origin.x, 0, accuracy: 0.001)
    XCTAssertEqual(local.origin.y, 0, accuracy: 0.001)
    XCTAssertEqual(local.width, 50, accuracy: 0.001)
  }

  func testLinearSegmentUnionPathReturnsNilWhenNotSegmented() {
    var configuration = FKProgressBarConfiguration()
    configuration.layout.segmentCount = 1
    let track = CGRect(x: 0, y: 0, width: 100, height: 8)

    let path = FKProgressBarLayoutEngine.linearSegmentUnionPath(
      track: track,
      configuration: configuration,
      filledSegments: 1,
      layoutDirection: .leftToRight
    )

    XCTAssertNil(path)
  }
}
