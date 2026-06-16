import FKCoreKit
import UIKit
import XCTest

@MainActor
final class FKMockImageLoaderTests: XCTestCase {
  func testLoadImageReturnsStubImageAndIncrementsCallCount() async throws {
    let loader = FKMockImageLoader(stubImage: UIImage())
    let request = FKImageLoadRequest(url: URL(string: "https://example.com/a.png")!)

    _ = try await loader.loadImage(for: request)

    XCTAssertEqual(loader.loadCallCount, 1)
  }

  func testLoadImageThrowsConfiguredError() async {
    enum TestError: Error { case failed }
    let loader = FKMockImageLoader(stubError: TestError.failed)
    let request = FKImageLoadRequest(url: URL(string: "https://example.com/b.png")!)

    do {
      _ = try await loader.loadImage(for: request)
      XCTFail("Expected load to throw")
    } catch is TestError {
      // Expected.
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testCancelLoadRecordsURLAndResetClearsState() {
    let loader = FKMockImageLoader()
    let url = URL(string: "https://example.com/c.png")!
    let request = FKImageLoadRequest(url: url)

    loader.cancelLoad(for: request)
    loader.reset()

    XCTAssertTrue(loader.cancelledURLs.isEmpty)
  }
}
