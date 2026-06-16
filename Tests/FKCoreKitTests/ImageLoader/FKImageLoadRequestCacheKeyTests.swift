import FKCoreKit
import XCTest

final class FKImageLoadRequestCacheKeyTests: XCTestCase {
  func testResolvedCacheKeyUsesCustomKeyWhenProvided() {
    let request = FKImageLoadRequest(
      url: URL(string: "https://cdn.example.com/a.png")!,
      cacheKey: "avatar-user-42"
    )
    XCTAssertEqual(request.resolvedCacheKey, "avatar-user-42")
  }

  func testResolvedCacheKeyIncludesTargetDimensions() {
    let request = FKImageLoadRequest(
      url: URL(string: "https://cdn.example.com/a.png")!,
      targetWidth: 120,
      targetHeight: 120
    )
    XCTAssertEqual(
      request.resolvedCacheKey,
      "https://cdn.example.com/a.png|w=120|h=120"
    )
  }

  func testResolvedCacheKeyUsesAbsoluteURLWhenNoOverride() {
    let url = URL(string: "https://cdn.example.com/banner.jpg")!
    let request = FKImageLoadRequest(url: url)
    XCTAssertEqual(request.resolvedCacheKey, url.absoluteString)
  }
}
