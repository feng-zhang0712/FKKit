@testable import FKUIKit
import XCTest

final class FKMediaGalleryImageLoadingMathTests: XCTestCase {
  func testRetentionRadiusDerivesFromMaxRetainedPages() {
    XCTAssertEqual(FKMediaGalleryImageLoadingMath.retentionRadius(for: 1), 0)
    XCTAssertEqual(FKMediaGalleryImageLoadingMath.retentionRadius(for: 3), 1)
    XCTAssertEqual(FKMediaGalleryImageLoadingMath.retentionRadius(for: 5), 2)
    XCTAssertEqual(FKMediaGalleryImageLoadingMath.retentionRadius(for: 0), 0)
  }

  func testDecodeTargetSizeReturnsZeroForEmptyBounds() {
    let size = FKMediaGalleryImageLoadingMath.decodeTargetSize(
      bounds: .zero,
      screenScale: 3,
      maximumZoomScale: 2,
      isCurrentPage: true
    )

    XCTAssertEqual(size, .zero)
  }

  func testDecodeTargetSizeAppliesZoomOnlyForCurrentPage() {
    let bounds = CGSize(width: 100, height: 200)
    let screenScale: CGFloat = 2
    let maximumZoomScale: CGFloat = 3

    let current = FKMediaGalleryImageLoadingMath.decodeTargetSize(
      bounds: bounds,
      screenScale: screenScale,
      maximumZoomScale: maximumZoomScale,
      isCurrentPage: true
    )
    let neighbor = FKMediaGalleryImageLoadingMath.decodeTargetSize(
      bounds: bounds,
      screenScale: screenScale,
      maximumZoomScale: maximumZoomScale,
      isCurrentPage: false
    )

    XCTAssertEqual(current, CGSize(width: 600, height: 1200))
    XCTAssertEqual(neighbor, CGSize(width: 200, height: 400))
    XCTAssertGreaterThan(current.width, neighbor.width)
  }

  func testDecodeTargetSizeClampsZoomFactorToAtLeastOne() {
    let size = FKMediaGalleryImageLoadingMath.decodeTargetSize(
      bounds: CGSize(width: 50, height: 50),
      screenScale: 2,
      maximumZoomScale: 0.5,
      isCurrentPage: true
    )

    XCTAssertEqual(size, CGSize(width: 100, height: 100))
  }
}
