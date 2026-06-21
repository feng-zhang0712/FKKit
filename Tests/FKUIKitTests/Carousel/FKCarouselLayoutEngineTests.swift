@testable import FKUIKit
import XCTest

final class FKCarouselLayoutEngineTests: XCTestCase {
  private func makeConfiguration(
    layoutMode: FKCarouselLayoutMode = .fullPage,
    heightStrategy: FKCarouselHeightStrategy = .aspectRatio(16.0 / 9.0),
    interPageSpacing: CGFloat = 0
  ) -> FKCarouselConfiguration {
    var configuration = FKCarouselConfiguration()
    configuration.layout.layoutMode = layoutMode
    configuration.layout.heightStrategy = heightStrategy
    configuration.layout.interPageSpacing = interPageSpacing
    configuration.layout.contentInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    return configuration
  }

  func testMetricsFullPageUsesAvailableWidthMinusInsets() {
    let configuration = makeConfiguration()
    let metrics = FKCarouselLayoutEngine.metrics(
      bounds: CGRect(x: 0, y: 0, width: 390, height: 400),
      configuration: configuration,
      safeAreaInsets: .zero
    )

    XCTAssertEqual(metrics.pageWidth, 358, accuracy: 0.001)
    XCTAssertTrue(metrics.usesPagingEnabled)
  }

  func testResolvedHeightUsesAspectRatio() {
    let height = FKCarouselLayoutEngine.resolvedHeight(
      width: 320,
      strategy: .aspectRatio(16.0 / 9.0)
    )

    XCTAssertEqual(height, 180, accuracy: 0.001)
  }

  func testResolvedHeightReturnsZeroForNonPositiveAspectRatio() {
    XCTAssertEqual(
      FKCarouselLayoutEngine.resolvedHeight(width: 100, strategy: .aspectRatio(0)),
      0,
      accuracy: 0.001
    )
  }

  func testCardPeekLayoutReducesPageWidthByPeekAndSpacing() {
    let configuration = makeConfiguration(
      layoutMode: .cardPeek(interPageSpacing: 12, peekWidth: 24),
      heightStrategy: .fixed(200)
    )

    let metrics = FKCarouselLayoutEngine.metrics(
      bounds: CGRect(x: 0, y: 0, width: 390, height: 300),
      configuration: configuration,
      safeAreaInsets: .zero
    )

    XCTAssertEqual(metrics.pageWidth, 322, accuracy: 0.001)
    XCTAssertEqual(metrics.pageSpan, 334, accuracy: 0.001)
    XCTAssertFalse(metrics.usesPagingEnabled)
  }

  func testFixedPageWidthCentersPageWithinAvailableWidth() {
    let configuration = makeConfiguration(
      layoutMode: .fixedPageWidth(200),
      heightStrategy: .fixed(120)
    )

    let metrics = FKCarouselLayoutEngine.metrics(
      bounds: CGRect(x: 0, y: 0, width: 390, height: 200),
      configuration: configuration,
      safeAreaInsets: .zero
    )

    XCTAssertEqual(metrics.pageWidth, 200, accuracy: 0.001)
    XCTAssertGreaterThan(metrics.sectionInset.left, configuration.layout.contentInsets.left)
  }

  func testContentOffsetScalesByPageSpan() {
    let metrics = FKCarouselLayoutEngine.Metrics(
      pageWidth: 300,
      pageHeight: 180,
      itemSize: CGSize(width: 300, height: 180),
      sectionInset: .zero,
      pageSpan: 312,
      collectionHeight: 180,
      indicatorSpacing: 8,
      usesPagingEnabled: false
    )

    let offset = FKCarouselLayoutEngine.contentOffset(forPhysicalIndex: 2, metrics: metrics)

    XCTAssertEqual(offset, CGPoint(x: 624, y: 0))
  }

  func testPhysicalIndexMapsFromContentOffset() {
    let metrics = FKCarouselLayoutEngine.Metrics(
      pageWidth: 300,
      pageHeight: 180,
      itemSize: CGSize(width: 300, height: 180),
      sectionInset: .zero,
      pageSpan: 300,
      collectionHeight: 180,
      indicatorSpacing: 0,
      usesPagingEnabled: true
    )

    XCTAssertEqual(
      FKCarouselLayoutEngine.physicalIndex(
        forContentOffset: CGPoint(x: 450, y: 0),
        metrics: metrics,
        pageCount: 5
      ),
      2
    )
  }

  func testScrollProgressReturnsFractionBetweenPages() {
    let metrics = FKCarouselLayoutEngine.Metrics(
      pageWidth: 100,
      pageHeight: 50,
      itemSize: CGSize(width: 100, height: 50),
      sectionInset: .zero,
      pageSpan: 100,
      collectionHeight: 50,
      indicatorSpacing: 0,
      usesPagingEnabled: true
    )

    let result = FKCarouselLayoutEngine.scrollProgress(
      forContentOffset: CGPoint(x: 150, y: 0),
      metrics: metrics,
      pageCount: 4
    )

    XCTAssertEqual(result.fromPage, 1)
    XCTAssertEqual(result.toPage, 2)
    XCTAssertEqual(result.progress, 0.5, accuracy: 0.001)
  }

  func testScrollProgressClampsBeforeFirstPageWhenRequested() {
    let metrics = FKCarouselLayoutEngine.Metrics(
      pageWidth: 100,
      pageHeight: 50,
      itemSize: CGSize(width: 100, height: 50),
      sectionInset: .zero,
      pageSpan: 100,
      collectionHeight: 50,
      indicatorSpacing: 0,
      usesPagingEnabled: true
    )

    let result = FKCarouselLayoutEngine.scrollProgress(
      forContentOffset: CGPoint(x: -40, y: 0),
      metrics: metrics,
      pageCount: 3,
      clampToPageBounds: true
    )

    XCTAssertEqual(result.fromPage, 0)
    XCTAssertEqual(result.toPage, 1)
    XCTAssertEqual(result.progress, 0, accuracy: 0.001)
  }

  func testIntrinsicHeightStrategyUsesResolver() {
    let configuration = makeConfiguration(heightStrategy: .intrinsicFromCurrentPage)

    let metrics = FKCarouselLayoutEngine.metrics(
      bounds: CGRect(x: 0, y: 0, width: 390, height: 400),
      configuration: configuration,
      safeAreaInsets: .zero,
      intrinsicPageHeightResolver: { width in width * 0.5 }
    )

    XCTAssertEqual(metrics.pageHeight, 179, accuracy: 0.001)
  }
}
