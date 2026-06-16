import FKUIKit
import XCTest

final class FKMediaNetworkConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesStandardRetryAndTimeoutValues() {
    let configuration = FKMediaNetworkConfiguration.default

    XCTAssertEqual(configuration.maxRetryCount, 3)
    XCTAssertEqual(configuration.retryBackoffBase, 1, accuracy: 0.001)
    XCTAssertEqual(configuration.connectionTimeout, 30, accuracy: 0.001)
    XCTAssertEqual(configuration.readTimeout, 60, accuracy: 0.001)
    XCTAssertTrue(configuration.allowsCellularAccess)
  }

  func testConfigurationStoresCustomRetryAndNetworkAccessFlags() {
    let configuration = FKMediaNetworkConfiguration(
      maxRetryCount: 5,
      retryBackoffBase: 2,
      connectionTimeout: 15,
      readTimeout: 45,
      allowsCellularAccess: false,
      allowsConstrainedNetworkAccess: false
    )

    XCTAssertEqual(configuration.maxRetryCount, 5)
    XCTAssertEqual(configuration.retryBackoffBase, 2, accuracy: 0.001)
    XCTAssertEqual(configuration.connectionTimeout, 15, accuracy: 0.001)
    XCTAssertEqual(configuration.readTimeout, 45, accuracy: 0.001)
    XCTAssertFalse(configuration.allowsCellularAccess)
    XCTAssertFalse(configuration.allowsConstrainedNetworkAccess)
  }
}
