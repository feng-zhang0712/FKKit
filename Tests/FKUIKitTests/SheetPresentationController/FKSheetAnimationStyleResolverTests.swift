@testable import FKUIKit
import UIKit
import XCTest

final class FKSheetAnimationStyleResolverTests: XCTestCase {
  private func resolve(
    layout: FKSheetPresentationConfiguration.Layout = .bottomSheet(.init()),
    preset: FKSheetAnimationPreset = .systemLike,
    duration: TimeInterval = 0.32,
    isPresentation: Bool = true,
    reduceMotionEnabled: Bool = false,
    interactionState: FKSheetAnimationStyleResolver.InteractionState = .nonInteractive
  ) -> FKSheetAnimationStyleResolver.TransitionStyle {
    var animationConfiguration = FKSheetAnimationConfiguration(preset: preset, duration: duration)
    return FKSheetAnimationStyleResolver.resolveTransitionStyle(
      layout: layout,
      animationConfiguration: animationConfiguration,
      isPresentation: isPresentation,
      reduceMotionEnabled: reduceMotionEnabled,
      interactionState: interactionState
    )
  }

  func testNonePresetReturnsZeroDurationTransition() {
    let style = resolve(preset: .none)

    XCTAssertEqual(style.duration, 0, accuracy: 0.001)
    XCTAssertEqual(style.initialAlpha, 1, accuracy: 0.001)
    XCTAssertEqual(style.finalAlpha, 1, accuracy: 0.001)
    XCTAssertEqual(style.initialScale, 1, accuracy: 0.001)
    XCTAssertEqual(style.finalScale, 1, accuracy: 0.001)
  }

  func testCenterLayoutUsesAlertLikeFamily() {
    let style = resolve(layout: .center(.init(size: .fixed(.init(width: 300, height: 400)))))

    XCTAssertEqual(style.family, .alertLikeCenter)
  }

  func testBottomSheetUsesSheetLikeFamily() {
    let style = resolve(layout: .bottomSheet(.init()))

    XCTAssertEqual(style.family, .sheetLike)
    XCTAssertEqual(style.initialScale, 1, accuracy: 0.001)
    XCTAssertEqual(style.finalScale, 1, accuracy: 0.001)
  }

  func testAlertLikePresentationUsesPopInScaleAndFade() {
    let style = resolve(
      layout: .center(.init(size: .fixed(.init(width: 280, height: 320)))),
      preset: .spring,
      isPresentation: true
    )

    XCTAssertEqual(style.initialScale, 1.08, accuracy: 0.001)
    XCTAssertEqual(style.finalScale, 1, accuracy: 0.001)
    XCTAssertEqual(style.initialAlpha, 0, accuracy: 0.001)
    XCTAssertEqual(style.finalAlpha, 1, accuracy: 0.001)
  }

  func testAlertLikeDismissUsesShrinkScaleAndFadeOut() {
    let style = resolve(
      layout: .center(.init(size: .fixed(.init(width: 280, height: 320)))),
      preset: .easeInOut,
      isPresentation: false
    )

    XCTAssertEqual(style.initialScale, 1, accuracy: 0.001)
    XCTAssertEqual(style.finalScale, 0.92, accuracy: 0.001)
    XCTAssertEqual(style.initialAlpha, 1, accuracy: 0.001)
    XCTAssertEqual(style.finalAlpha, 0, accuracy: 0.001)
  }

  func testReduceMotionUsesShortFadeForCenterLayout() {
    let style = resolve(
      layout: .center(.init(size: .fixed(.init(width: 280, height: 320)))),
      duration: 0.5,
      isPresentation: true,
      reduceMotionEnabled: true
    )

    XCTAssertLessThanOrEqual(style.duration, 0.2)
    XCTAssertEqual(style.initialAlpha, 0, accuracy: 0.001)
    XCTAssertEqual(style.finalAlpha, 1, accuracy: 0.001)
  }

  func testReduceMotionKeepsUnitScaleForSheetLikeLayout() {
    let style = resolve(
      layout: .bottomSheet(.init()),
      isPresentation: true,
      reduceMotionEnabled: true
    )

    XCTAssertEqual(style.initialScale, 1, accuracy: 0.001)
    XCTAssertEqual(style.finalScale, 1, accuracy: 0.001)
  }

  func testInteractiveDismissCapsAlertLikeDuration() {
    let style = resolve(
      layout: .center(.init(size: .fixed(.init(width: 280, height: 320)))),
      preset: .spring,
      duration: 0.34,
      isPresentation: false,
      interactionState: .interactive
    )

    XCTAssertLessThanOrEqual(style.duration, 0.2)
  }

  func testSheetLikeDismissUsesShorterDurationThanPresentationForSystemLikePreset() {
    let present = resolve(
      layout: .bottomSheet(.init()),
      preset: .systemLike,
      isPresentation: true
    )
    let dismiss = resolve(
      layout: .bottomSheet(.init()),
      preset: .systemLike,
      isPresentation: false
    )

    XCTAssertLessThan(dismiss.duration, present.duration)
  }

  func testFadePresetUsesLinearTimingForSheetLikeLayout() {
    let style = resolve(layout: .bottomSheet(.init()), preset: .fade, isPresentation: true)

    if case .curve(let curve) = style.timing {
      XCTAssertEqual(curve, .linear)
    } else {
      XCTFail("Expected linear curve timing")
    }
  }
}
