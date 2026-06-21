@testable import FKUIKit
import XCTest

final class FKAvatarInitialsGeneratorTests: XCTestCase {
  func testInitialsFromTwoWordDisplayName() {
    XCTAssertEqual(FKAvatarInitialsGenerator.initials(from: "Ada Lovelace"), "AL")
  }

  func testInitialsFromSingleWordUsesFirstTwoLetters() {
    XCTAssertEqual(FKAvatarInitialsGenerator.initials(from: "Grace"), "GR")
  }

  func testInitialsFromCJKUsesFirstGrapheme() {
    XCTAssertEqual(FKAvatarInitialsGenerator.initials(from: "张三"), "张")
  }

  func testInitialsReturnsEmptyForBlankInput() {
    XCTAssertEqual(FKAvatarInitialsGenerator.initials(from: "   "), "")
    XCTAssertEqual(FKAvatarInitialsGenerator.initials(from: "---"), "")
  }

  func testBackgroundColorIsStableForSameDisplayName() {
    let first = FKAvatarInitialsGenerator.backgroundColor(for: "Stable Name")
    let second = FKAvatarInitialsGenerator.backgroundColor(for: "Stable Name")

    XCTAssertTrue(first.isEqual(second))
  }

  func testBackgroundColorDiffersForDifferentNames() {
    let first = FKAvatarInitialsGenerator.backgroundColor(for: "Alice")
    let second = FKAvatarInitialsGenerator.backgroundColor(for: "Bob")

    XCTAssertFalse(first.isEqual(second))
  }

  func testScaledFontNeverDropsBelowMinimumSize() {
    let base = UIFont.systemFont(ofSize: 14)
    let scaled = FKAvatarInitialsGenerator.scaledFont(base: base, avatarDiameter: 12)

    XCTAssertGreaterThanOrEqual(scaled.pointSize, 10)
  }

  func testScaledFontScalesWithAvatarDiameter() {
    let base = UIFont.systemFont(ofSize: 14)
    let small = FKAvatarInitialsGenerator.scaledFont(base: base, avatarDiameter: 40)
    let large = FKAvatarInitialsGenerator.scaledFont(base: base, avatarDiameter: 80)

    XCTAssertGreaterThan(large.pointSize, small.pointSize)
  }
}
