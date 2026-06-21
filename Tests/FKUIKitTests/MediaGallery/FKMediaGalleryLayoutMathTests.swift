@testable import FKUIKit
import UIKit
import XCTest

final class FKMediaGalleryLayoutMathTests: XCTestCase {
  func testAspectFitFrameCentersContentWithinBounds() {
    let bounds = CGRect(x: 0, y: 0, width: 200, height: 100)
    let contentSize = CGSize(width: 400, height: 200)

    let frame = FKMediaGalleryLayoutMath.aspectFitFrame(contentSize: contentSize, in: bounds)

    XCTAssertEqual(frame.midX, bounds.midX, accuracy: 0.001)
    XCTAssertEqual(frame.midY, bounds.midY, accuracy: 0.001)
    XCTAssertEqual(frame.width, 200, accuracy: 0.001)
    XCTAssertEqual(frame.height, 100, accuracy: 0.001)
  }

  func testAspectFitFrameReturnsZeroForInvalidInputs() {
    XCTAssertEqual(
      FKMediaGalleryLayoutMath.aspectFitFrame(contentSize: .zero, in: CGRect(x: 0, y: 0, width: 100, height: 100)),
      .zero
    )
    XCTAssertEqual(
      FKMediaGalleryLayoutMath.aspectFitFrame(contentSize: CGSize(width: 100, height: 100), in: .zero),
      .zero
    )
  }

  func testResolvedImageSizeUsesPixelDimensionsWhenAvailable() {
    let image = UIImage(systemName: "photo")!
    let scaled = UIImage(cgImage: image.cgImage!, scale: 2, orientation: .up)

    let size = FKMediaGalleryLayoutMath.resolvedImageSize(from: scaled)

    XCTAssertEqual(size.width, scaled.size.width * 2, accuracy: 0.001)
    XCTAssertEqual(size.height, scaled.size.height * 2, accuracy: 0.001)
  }

  func testResolvedImageSizeReturnsZeroForNilImage() {
    XCTAssertEqual(FKMediaGalleryLayoutMath.resolvedImageSize(from: nil), .zero)
  }

  func testAspectFitFrameInterpolatedMatchesEndpoints() {
    let contentSize = CGSize(width: 160, height: 90)
    let start = CGRect(x: 0, y: 0, width: 200, height: 200)
    let end = CGRect(x: 0, y: 0, width: 400, height: 300)

    let atStart = FKMediaGalleryLayoutMath.aspectFitFrameInterpolated(
      contentSize: contentSize,
      startContainer: start,
      endContainer: end,
      progress: 0
    )
    let atEnd = FKMediaGalleryLayoutMath.aspectFitFrameInterpolated(
      contentSize: contentSize,
      startContainer: start,
      endContainer: end,
      progress: 1
    )

    XCTAssertEqual(atStart, FKMediaGalleryLayoutMath.aspectFitFrame(contentSize: contentSize, in: start))
    XCTAssertEqual(atEnd, FKMediaGalleryLayoutMath.aspectFitFrame(contentSize: contentSize, in: end))
  }

  func testAspectFitFrameInterpolatedClampsProgress() {
    let contentSize = CGSize(width: 100, height: 100)
    let start = CGRect(x: 0, y: 0, width: 100, height: 100)
    let end = CGRect(x: 0, y: 0, width: 200, height: 200)

    let below = FKMediaGalleryLayoutMath.aspectFitFrameInterpolated(
      contentSize: contentSize,
      startContainer: start,
      endContainer: end,
      progress: -1
    )
    let above = FKMediaGalleryLayoutMath.aspectFitFrameInterpolated(
      contentSize: contentSize,
      startContainer: start,
      endContainer: end,
      progress: 2
    )

    XCTAssertEqual(below, FKMediaGalleryLayoutMath.aspectFitFrame(contentSize: contentSize, in: start))
    XCTAssertEqual(above, FKMediaGalleryLayoutMath.aspectFitFrame(contentSize: contentSize, in: end))
  }
}
