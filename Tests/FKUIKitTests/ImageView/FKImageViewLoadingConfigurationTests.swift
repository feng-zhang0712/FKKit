import FKUIKit
import XCTest

final class FKImageViewLoadingConfigurationTests: XCTestCase {
  func testDefaultConfigurationLoadsAutomaticallyFromBounds() {
    let configuration = FKImageViewLoadingConfiguration()

    if case .none = configuration.placeholder {
      XCTAssertEqual(configuration.targetSizePolicy, .automaticFromBounds)
    } else {
      XCTFail("Expected none placeholder")
    }
    XCTAssertTrue(configuration.loadsAutomatically)
    XCTAssertTrue(configuration.checksMemoryCachePreview)
  }

  func testConfigurationStoresExplicitTargetSizeAndCacheFlags() {
    let configuration = FKImageViewLoadingConfiguration(
      targetSizePolicy: .explicit(CGSize(width: 120, height: 120)),
      loadsAutomatically: false,
      excludesFromDiskCache: true,
      showsPlaceholderWhenIdle: true
    )

    if case .explicit(let size) = configuration.targetSizePolicy {
      XCTAssertEqual(size.width, 120, accuracy: 0.001)
      XCTAssertEqual(size.height, 120, accuracy: 0.001)
    } else {
      XCTFail("Expected explicit target size policy")
    }
    XCTAssertFalse(configuration.loadsAutomatically)
    XCTAssertTrue(configuration.excludesFromDiskCache)
    XCTAssertTrue(configuration.showsPlaceholderWhenIdle)
  }
}
