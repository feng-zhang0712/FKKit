@testable import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKButtonStateTests: FKUIKitTestCase {
  private var button: FKButton!

  override func setUp() {
    super.setUp()
    button = FKButton(content: .textOnly)
  }

  override func tearDown() {
    button = nil
    super.tearDown()
  }

  func testSetTitleRegistersNormalStateTitle() {
    button.setTitle(FKButtonLabelConfiguration(text: "Save"), for: .normal)
    XCTAssertEqual(button.title(for: .normal)?.text, "Save")
  }

  func testSetModelAppliesBundledTitle() {
    button.setModel(
      FKButtonStateModel(title: FKButtonLabelConfiguration(text: "Continue")),
      for: .normal
    )
    XCTAssertEqual(button.title(for: .normal)?.text, "Continue")
  }

  func testSetModelNilClearsRegisteredNormalStateContent() {
    button.setModel(
      FKButtonStateModel(title: FKButtonLabelConfiguration(text: "Temporary")),
      for: .normal
    )
    button.setModel(nil, for: .normal)
    XCTAssertNil(button.title(for: .normal))
  }

  func testIsEnabledUpdatesControlState() {
    button.isEnabled = false
    XCTAssertFalse(button.isEnabled)
    button.isEnabled = true
    XCTAssertTrue(button.isEnabled)
  }

  func testSetLoadingBlocksInteraction() {
    button.setLoading(true)
    XCTAssertTrue(button.isLoading)
    XCTAssertFalse(button.isUserInteractionEnabled)

    button.setLoading(false)
    XCTAssertFalse(button.isLoading)
    XCTAssertTrue(button.isUserInteractionEnabled)
  }

  func testMinimumTouchTargetSizeExpandsHitTesting() {
    button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    button.minimumTouchTargetSize = CGSize(width: 44, height: 44)
    layoutIfNeeded(button)

    XCTAssertTrue(button.point(inside: CGPoint(x: 12, y: 12), with: nil))
    XCTAssertTrue(button.point(inside: CGPoint(x: -4, y: 12), with: nil))
  }

  func testGradientAppearanceEnablesBackgroundGradientLayer() {
    button.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
    var appearance = FKButtonAppearance()
    appearance.backgroundGradient = FKButtonLinearGradient(colors: [.systemBlue, .systemPurple])
    button.setAppearance(appearance, for: .normal)
    layoutIfNeeded(button)

    XCTAssertFalse(button.backgroundGradientLayer.isHidden)
    XCTAssertEqual(button.backgroundGradientLayer.colors?.count, 2)
  }

  func testTextAndImageContentAppliesTitleAndImage() {
    let button = FKButton(content: .textAndImage(.leading))
    button.setTitle(FKButtonLabelConfiguration(text: "Download"), for: .normal)
    button.setImage(FKButtonImageConfiguration(image: UIImage()), slot: .leading, for: .normal)
    layoutIfNeeded(button)

    XCTAssertEqual(button.title(for: .normal)?.text, "Download")
    XCTAssertNotNil(button.image(slot: .leading, for: .normal))
  }

  private func layoutIfNeeded(_ view: UIView) {
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }
}
