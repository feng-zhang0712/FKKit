@testable import FKUIKit
import UIKit
import XCTest

final class FKRatingIconResolverTests: XCTestCase {
  func testPresetStarIconsResolveNonNilImages() {
    let appearance = FKRatingAppearanceConfiguration(iconStyle: .preset(.star))

    XCTAssertNotNil(FKRatingIconResolver.emptyImage(for: appearance))
    XCTAssertNotNil(FKRatingIconResolver.filledImage(for: appearance))
  }

  func testPresetHeartIconsResolveNonNilImages() {
    let appearance = FKRatingAppearanceConfiguration(iconStyle: .preset(.heart))

    XCTAssertNotNil(FKRatingIconResolver.emptyImage(for: appearance))
    XCTAssertNotNil(FKRatingIconResolver.filledImage(for: appearance))
  }

  func testPresetThumbUpIconsResolveNonNilImages() {
    let appearance = FKRatingAppearanceConfiguration(iconStyle: .preset(.thumbUp))

    XCTAssertNotNil(FKRatingIconResolver.emptyImage(for: appearance))
    XCTAssertNotNil(FKRatingIconResolver.filledImage(for: appearance))
  }

  func testCustomSymbolNamesResolveImages() {
    let appearance = FKRatingAppearanceConfiguration(
      iconStyle: .symbols(empty: "circle", filled: "circle.fill", half: nil)
    )

    XCTAssertNotNil(FKRatingIconResolver.emptyImage(for: appearance))
    XCTAssertNotNil(FKRatingIconResolver.filledImage(for: appearance))
  }

  func testCustomImagesApplyRenderingMode() {
    let empty = UIImage(systemName: "star")!
    let filled = UIImage(systemName: "star.fill")!
    var appearance = FKRatingAppearanceConfiguration(
      iconStyle: .images(empty: empty, filled: filled, half: nil)
    )
    appearance.renderingMode = .alwaysOriginal

    XCTAssertEqual(FKRatingIconResolver.filledImage(for: appearance)?.renderingMode, .alwaysOriginal)
  }

  func testSymbolConfigurationIsAppliedToPresetIcons() {
    let configuration = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
    var appearance = FKRatingAppearanceConfiguration(iconStyle: .preset(.star))
    appearance.symbolConfiguration = configuration

    let defaultAppearance = FKRatingAppearanceConfiguration(iconStyle: .preset(.star))
    let configured = FKRatingIconResolver.filledImage(for: appearance)
    let baseline = FKRatingIconResolver.filledImage(for: defaultAppearance)

    XCTAssertNotNil(configured)
    XCTAssertNotEqual(configured?.size, baseline?.size)
  }
}
