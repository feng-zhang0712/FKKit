import FKCoreKit
import XCTest

final class FKNetworkConfigurationTests: XCTestCase {
  func testCurrentReturnsActiveEnvironmentConfig() {
    let devURL = URL(string: "https://dev.example.com")!
    let prodURL = URL(string: "https://prod.example.com")!
    let configuration = FKNetworkConfiguration(
      environment: .testing,
      environmentMap: [
        .development: FKEnvironmentConfig(baseURL: devURL),
        .testing: FKEnvironmentConfig(baseURL: prodURL, timeout: 15),
      ]
    )

    let current = configuration.current

    XCTAssertEqual(current?.baseURL, prodURL)
    XCTAssertEqual(current?.timeout, 15)
  }

  func testCurrentReturnsNilWhenEnvironmentIsUnmapped() {
    let configuration = FKNetworkConfiguration(
      environment: .production,
      environmentMap: [
        .development: FKEnvironmentConfig(baseURL: URL(string: "https://dev.example.com")!),
      ]
    )

    XCTAssertNil(configuration.current)
  }
}
