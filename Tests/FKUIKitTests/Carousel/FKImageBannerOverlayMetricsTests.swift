@testable import FKUIKit
import XCTest

@MainActor
final class FKImageBannerOverlayMetricsTests: XCTestCase {
  func testAdditionalBannerHeightReturnsZeroWhenPolicyIsNotGrowBanner() {
    var configuration = FKImageBannerConfiguration()
    configuration.overlayExpansionPolicy = .fixedBannerHeight
    let slide = FKImageBannerSlide(
      id: "1",
      imageSource: .url(URL(string: "https://example.com/banner.jpg")!),
      title: "Title",
      subtitle: "Subtitle"
    )

    let height = FKImageBannerOverlayMetrics.additionalBannerHeight(
      slide: slide,
      configuration: configuration,
      pageWidth: 320,
      traitCollection: UITraitCollection()
    )

    XCTAssertEqual(height, 0, accuracy: 0.001)
  }

  func testAdditionalBannerHeightReturnsZeroWithoutSlide() {
    var configuration = FKImageBannerConfiguration()
    configuration.overlayExpansionPolicy = .growBanner

    let height = FKImageBannerOverlayMetrics.additionalBannerHeight(
      slide: nil,
      configuration: configuration,
      pageWidth: 320,
      traitCollection: UITraitCollection()
    )

    XCTAssertEqual(height, 0, accuracy: 0.001)
  }

  func testAdditionalBannerHeightReturnsZeroForZeroPageWidth() {
    var configuration = FKImageBannerConfiguration()
    configuration.overlayExpansionPolicy = .growBanner
    let slide = FKImageBannerSlide(
      id: "1",
      imageSource: .url(URL(string: "https://example.com/banner.jpg")!),
      title: "Title"
    )

    let height = FKImageBannerOverlayMetrics.additionalBannerHeight(
      slide: slide,
      configuration: configuration,
      pageWidth: 0,
      traitCollection: UITraitCollection()
    )

    XCTAssertEqual(height, 0, accuracy: 0.001)
  }

  func testAdditionalBannerHeightIsNonNegativeForVisibleOverlayContent() {
    var configuration = FKImageBannerConfiguration()
    configuration.overlayExpansionPolicy = .growBanner
    configuration.overlayVisibility = .always
    configuration.carousel.layout.heightStrategy = .aspectRatio(16.0 / 9.0)
    let slide = FKImageBannerSlide(
      id: "1",
      imageSource: .url(URL(string: "https://example.com/banner.jpg")!),
      title: "Summer Collection",
      subtitle: "New arrivals every week",
      overlayStyle: FKImageBannerOverlayStyle(
        ctaTitle: "Shop now",
        visibility: .always
      )
    )

    let height = FKImageBannerOverlayMetrics.additionalBannerHeight(
      slide: slide,
      configuration: configuration,
      pageWidth: 390,
      traitCollection: UITraitCollection()
    )

    XCTAssertGreaterThanOrEqual(height, 0)
  }
}
