@testable import FKUIKit
import FKCoreKit
import XCTest

@MainActor
final class FKImageViewBehaviorTests: FKUIKitTestCase {
  func testRetryIsNoOpWhenRetryIsDisabled() async {
    var configuration = FKImageViewConfiguration()
    configuration.failure.isRetryEnabled = false
    let loader = FKMockImageLoader(stubError: URLError(.notConnectedToInternet))
    let imageView = FKImageView(configuration: configuration)
    imageView.imageLoader = loader
    imageView.currentURL = URL(string: "https://example.com/image.png")

    imageView.retry()
    try? await Task.sleep(nanoseconds: 50_000_000)

    XCTAssertEqual(loader.loadCallCount, 0)
  }

  func testRetryIsNoOpWhenURLIsMissing() {
    var configuration = FKImageViewConfiguration()
    configuration.failure.isRetryEnabled = true
    let loader = FKMockImageLoader()
    let imageView = FKImageView(configuration: configuration)
    imageView.imageLoader = loader

    imageView.retry()

    XCTAssertEqual(loader.loadCallCount, 0)
  }

  func testRetryRespectsDebounceInterval() async {
    var configuration = FKImageViewConfiguration()
    configuration.failure.isRetryEnabled = true
    configuration.interaction.retryDebounceInterval = 60
    let loader = FKMockImageLoader(stubError: URLError(.notConnectedToInternet))
    let imageView = FKImageView(configuration: configuration)
    imageView.imageLoader = loader
    imageView.currentURL = URL(string: "https://example.com/debounce.png")
    imageView.lastRetryDate = Date()

    imageView.retry()
    try? await Task.sleep(nanoseconds: 50_000_000)
    XCTAssertEqual(loader.loadCallCount, 0)

    imageView.lastRetryDate = Date().addingTimeInterval(-120)
    imageView.retry()
    try? await Task.sleep(nanoseconds: 100_000_000)
    XCTAssertEqual(loader.loadCallCount, 1)
  }
}
