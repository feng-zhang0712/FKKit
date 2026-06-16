import FKUIKit
import XCTest

final class FKTabBarAccessoryIconConfigurationTests: XCTestCase {
  func testResolvedPrefersDisabledThenSelectedThenNormal() {
    let configuration = FKTabBarAccessoryIconConfiguration(
      normal: .init(source: .systemSymbol(name: "chevron.down"), style: .init(pointSize: 12)),
      selected: .init(source: .systemSymbol(name: "chevron.up"), style: .init(pointSize: 12)),
      disabled: .init(source: .systemSymbol(name: "minus"), style: .init(pointSize: 10))
    )

    XCTAssertEqual(configuration.resolved(isSelected: false, isEnabled: true).source, .systemSymbol(name: "chevron.down"))
    XCTAssertEqual(configuration.resolved(isSelected: true, isEnabled: true).source, .systemSymbol(name: "chevron.up"))
    XCTAssertEqual(configuration.resolved(isSelected: true, isEnabled: false).source, .systemSymbol(name: "minus"))
  }

  func testAccessoryIconStyleClampsPointSizeAndSpacing() {
    let style = FKTabBarAccessoryIconStyle(pointSize: 0, spacingToTitle: -4)

    XCTAssertEqual(style.pointSize, 1, accuracy: 0.001)
    XCTAssertEqual(style.spacingToTitle, 0, accuracy: 0.001)
  }
}
