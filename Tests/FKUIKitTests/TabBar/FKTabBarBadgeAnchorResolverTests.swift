@testable import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKTabBarBadgeAnchorResolverTests: FKUIKitTestCase {
  func testVerticalAxisAnchorsBadgeOnImageWhenBothImageAndTitlePresent() {
    let button = FKButton(content: .textAndImage(.leading))
    button.axis = .vertical
    button.setTitle(FKButtonLabelConfiguration(text: "Home"), for: .normal)
    button.setImage(FKButtonImageConfiguration(image: UIImage()), slot: .leading, for: .normal)
    layoutIfNeeded(button)

    let target = FKTabBarBadgeAnchorResolver.resolveTargetView(button: button)

    XCTAssertTrue(target === button.leadingImageView || target === button.imageView)
  }

  func testHorizontalAxisAnchorsBadgeOnTitleWhenBothImageAndTitlePresent() {
    let button = FKButton(content: .textAndImage(.leading))
    button.axis = .horizontal
    button.setTitle(FKButtonLabelConfiguration(text: "Home"), for: .normal)
    button.setImage(FKButtonImageConfiguration(image: UIImage()), slot: .leading, for: .normal)
    layoutIfNeeded(button)

    let target = FKTabBarBadgeAnchorResolver.resolveTargetView(button: button)

    XCTAssertTrue(target === button.titleLabel)
  }

  func testVerticalAxisFallsBackToTitleWhenImageMissing() {
    let button = FKButton(content: .textOnly)
    button.axis = .vertical
    button.setTitle(FKButtonLabelConfiguration(text: "Profile"), for: .normal)
    layoutIfNeeded(button)

    let target = FKTabBarBadgeAnchorResolver.resolveTargetView(button: button)

    XCTAssertTrue(target === button.titleLabel)
  }

  func testHorizontalAxisFallsBackToImageWhenTitleMissing() {
    let button = FKButton(content: .imageOnly)
    button.axis = .horizontal
    button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
    button.setImage(
      FKButtonImageConfiguration(image: UIImage(systemName: "house")!),
      slot: .leading,
      for: .normal
    )
    layoutIfNeeded(button)

    let target = FKTabBarBadgeAnchorResolver.resolveTargetView(button: button)

    XCTAssertTrue(
      target === button.leadingImageView
        || target === button.imageView
        || target === button.trailingImageView
    )
  }

  private func layoutIfNeeded(_ view: UIView) {
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }
}
