import FKCoreKit
import XCTest

final class FKImageLoaderURLSessionSettingsTests: XCTestCase {
  func testInitClampsZeroConnectionsPerHostToOne() {
    let settings = FKImageLoaderURLSessionSettings(httpMaximumConnectionsPerHost: 0)

    XCTAssertEqual(settings.httpMaximumConnectionsPerHost, 1)
  }

  func testMakeConfigurationAppliesTimeoutAndConnectivityFlags() {
    let settings = FKImageLoaderURLSessionSettings(
      timeoutIntervalForRequest: 42,
      waitsForConnectivity: false,
      httpMaximumConnectionsPerHost: 3
    )

    let configuration = settings.makeConfiguration()

    XCTAssertEqual(configuration.timeoutIntervalForRequest, 42, accuracy: 0.001)
    XCTAssertFalse(configuration.waitsForConnectivity)
    XCTAssertEqual(configuration.httpMaximumConnectionsPerHost, 3)
  }
}
