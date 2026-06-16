import FKCoreKit
import XCTest

final class FKImageLoaderConfigurationTests: XCTestCase {
  func testInitClampsConcurrentDecodeAndPrefetchCountsToAtLeastOne() {
    let configuration = FKImageLoaderConfiguration(
      maxConcurrentDecodes: 0,
      maxConcurrentPrefetches: -3
    )

    XCTAssertEqual(configuration.maxConcurrentDecodes, 1)
    XCTAssertEqual(configuration.maxConcurrentPrefetches, 1)
  }

  func testInitClampsNegativeDiskIndexPersistDelayToZero() {
    let configuration = FKImageLoaderConfiguration(diskIndexPersistDelay: -1)

    XCTAssertEqual(configuration.diskIndexPersistDelay, 0, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesProductionCacheLimits() {
    let configuration = FKImageLoaderConfiguration()

    XCTAssertEqual(configuration.memoryCostLimit, FKImageLoaderConfiguration.defaultMemoryCostLimit)
    XCTAssertEqual(configuration.diskSizeLimit, FKImageLoaderConfiguration.defaultDiskSizeLimit)
    XCTAssertTrue(configuration.isCachingEnabled)
  }
}
