@testable import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKExpandableTextMeasurementWidthTests: FKUIKitTestCase {
  func testResolveUsesLabelBoundsWhenReady() {
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 44))

    let resolved = FKExpandableTextMeasurementWidth.resolve(for: label)

    XCTAssertEqual(resolved.width, 240, accuracy: 0.001)
    XCTAssertFalse(resolved.needsDeferredRefresh)
  }

  func testResolveUsesPreferredMaxLayoutWidthWhenBoundsAreZero() {
    let label = UILabel(frame: .zero)
    label.preferredMaxLayoutWidth = 280

    let resolved = FKExpandableTextMeasurementWidth.resolve(for: label)

    XCTAssertEqual(resolved.width, 280, accuracy: 0.001)
    XCTAssertTrue(resolved.needsDeferredRefresh)
  }

  func testResolveWalksAncestorWidthWhenLabelHasNoBounds() {
    let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
    let label = UILabel(frame: .zero)
    container.addSubview(label)

    let resolved = FKExpandableTextMeasurementWidth.resolve(for: label)

    XCTAssertEqual(resolved.width, 320, accuracy: 0.001)
    XCTAssertTrue(resolved.needsDeferredRefresh)
  }

  func testResolveUsesScreenWidthAsLastResortForLabel() {
    let label = UILabel(frame: .zero)

    let resolved = FKExpandableTextMeasurementWidth.resolve(for: label)

    XCTAssertEqual(resolved.width, UIScreen.main.bounds.width, accuracy: 0.001)
    XCTAssertTrue(resolved.needsDeferredRefresh)
  }

  func testResolveUsesTextViewBoundsWhenReady() {
    let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 120))

    let resolved = FKExpandableTextMeasurementWidth.resolve(for: textView)

    XCTAssertEqual(resolved.width, 300, accuracy: 0.001)
    XCTAssertFalse(resolved.needsDeferredRefresh)
  }
}
