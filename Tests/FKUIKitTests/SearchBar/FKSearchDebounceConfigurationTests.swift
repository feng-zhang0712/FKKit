import FKUIKit
import XCTest

final class FKSearchDebounceConfigurationTests: XCTestCase {
  func testDefaultConfigurationEnablesDebounce() {
    let config = FKSearchDebounceConfiguration()
    XCTAssertTrue(config.isDebounceEnabled)
    XCTAssertEqual(config.debounceInterval, 0.35, accuracy: 0.001)
  }

  func testMinimumQueryLengthDefaultsToZero() {
    let config = FKSearchDebounceConfiguration()
    XCTAssertEqual(config.minimumQueryLengthForSearchCallback, 0)
  }

  func testBarConfigurationCarriesDebounceSettings() {
    let debounce = FKSearchDebounceConfiguration(
      debounceInterval: 0.5,
      isDebounceEnabled: false,
      minimumQueryLengthForSearchCallback: 2
    )
    let bar = FKSearchBarConfiguration(debounce: debounce)
    XCTAssertEqual(bar.debounce, debounce)
  }
}
