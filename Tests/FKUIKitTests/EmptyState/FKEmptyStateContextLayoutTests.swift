@testable import FKUIKit
import UIKit
import XCTest

final class FKEmptyStateContextLayoutTests: XCTestCase {
  func testFullPagePresetUsesLargestImageAndWidth() {
    let preset = FKEmptyStateContextLayout.preset(for: .fullPage)

    XCTAssertEqual(preset.imageSize, CGSize(width: 96, height: 96))
    XCTAssertEqual(preset.maxContentWidth, 360, accuracy: 0.001)
    XCTAssertEqual(preset.contentAlignment, .center)
  }

  func testCardPresetUsesCompactMetrics() {
    let preset = FKEmptyStateContextLayout.preset(for: .card)

    XCTAssertEqual(preset.imageSize, CGSize(width: 48, height: 48))
    XCTAssertEqual(preset.maxContentWidth, 240, accuracy: 0.001)
  }

  func testDrawerPresetAlignsContentToTop() {
    let preset = FKEmptyStateContextLayout.preset(for: .drawer)

    XCTAssertEqual(preset.contentAlignment, .top)
  }

  func testResolvedLayoutUsesExplicitImageSizeWhenProvided() {
    var configuration = FKEmptyStateConfiguration()
    configuration.layout.imageSize = CGSize(width: 40, height: 40)
    configuration.content.image = FKEmptyStateImageContent(image: UIImage())

    let resolved = FKEmptyStateResolvedLayout(configuration: configuration)

    XCTAssertEqual(resolved.imageSize, CGSize(width: 40, height: 40))
  }

  func testResolvedLayoutOmitsImageSizeWhenNoImageProvided() {
    var configuration = FKEmptyStateConfiguration()
    configuration.layout.context = .section

    let resolved = FKEmptyStateResolvedLayout(configuration: configuration)

    XCTAssertNil(resolved.imageSize)
  }

  func testResolvedLayoutFallsBackToContextPresetInsets() {
    var configuration = FKEmptyStateConfiguration()
    configuration.layout.context = .search

    let resolved = FKEmptyStateResolvedLayout(configuration: configuration)
    let preset = FKEmptyStateContextLayout.preset(for: .search)

    XCTAssertEqual(resolved.contentInsets, preset.contentInsets)
    XCTAssertEqual(resolved.verticalSpacing, preset.verticalSpacing)
  }

  func testResolvedLayoutHonorsExplicitOverrides() {
    var configuration = FKEmptyStateConfiguration()
    configuration.layout.maxContentWidth = 180
    configuration.layout.verticalSpacing = 20
    configuration.layout.contentAlignment = .top

    let resolved = FKEmptyStateResolvedLayout(configuration: configuration)

    XCTAssertEqual(resolved.maxContentWidth, 180, accuracy: 0.001)
    XCTAssertEqual(resolved.verticalSpacing, 20, accuracy: 0.001)
    XCTAssertEqual(resolved.contentAlignment, .top)
  }

  func testResolvedLayoutScalesPresetImageSizeWithDensity() {
    var configuration = FKEmptyStateConfiguration()
    configuration.layout.context = .list
    configuration.layout.density = .compact
    configuration.content.image = FKEmptyStateImageContent(image: UIImage())

    let resolved = FKEmptyStateResolvedLayout(configuration: configuration)
    let preset = FKEmptyStateContextLayout.preset(for: .list)
    let metrics = FKEmptyStateLayoutMetrics(density: .compact)

    XCTAssertEqual(resolved.imageSize, metrics.imageSize(from: preset.imageSize))
  }
}
