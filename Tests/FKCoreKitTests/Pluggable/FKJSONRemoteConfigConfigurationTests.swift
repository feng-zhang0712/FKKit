import FKCoreKit
import XCTest

final class FKJSONRemoteConfigConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesMainBundleAndCacheDirectory() {
    let configuration = FKJSONRemoteConfigConfiguration()

    XCTAssertNil(configuration.bundleResourceName)
    XCTAssertNil(configuration.remoteURL)
    XCTAssertEqual(configuration.fetchTimeout, 30, accuracy: 0.001)
    XCTAssertEqual(configuration.cacheDirectoryName, "FKRemoteConfig")
  }

  func testConfigurationStoresCustomResourceAndRemoteURL() {
    let url = URL(string: "https://example.com/config.json")!
    let configuration = FKJSONRemoteConfigConfiguration(
      bundleResourceName: "defaults",
      remoteURL: url,
      fetchTimeout: 15,
      cacheDirectoryName: nil
    )

    XCTAssertEqual(configuration.bundleResourceName, "defaults")
    XCTAssertEqual(configuration.remoteURL, url)
    XCTAssertEqual(configuration.fetchTimeout, 15, accuracy: 0.001)
    XCTAssertNil(configuration.cacheDirectoryName)
  }
}
