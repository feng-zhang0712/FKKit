import FKCoreKit
import UIKit
import XCTest

@MainActor
final class FKImageLoaderTests: XCTestCase {
  private var tempDirectory: URL!

  override func setUp() {
    super.setUp()
    tempDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("FKImageLoaderTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    StubImageURLProtocol.reset()
  }

  override func tearDown() {
    StubImageURLProtocol.reset()
    try? FileManager.default.removeItem(at: tempDirectory)
    tempDirectory = nil
    super.tearDown()
  }

  func testLoadImageResultReturnsHTTPStatusFor404() async {
    let imageURL = URL(string: "https://image-loader.test/missing.png")!
    StubImageURLProtocol.nextResponse = (
      Data(),
      HTTPURLResponse(url: imageURL, statusCode: 404, httpVersion: nil, headerFields: nil)
    )

    let loader = makeLoader(useStubProtocol: true)
    let request = FKImageLoadRequest(url: imageURL)

    do {
      _ = try await loader.loadImageResult(for: request)
      XCTFail("Expected httpStatus error")
    } catch let error as FKImageLoaderError {
      XCTAssertEqual(error, .httpStatus(code: 404))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testLoadImageResultDecodesLocalFileURL() async throws {
    let fileURL = tempDirectory.appendingPathComponent("local.png")
    let pngData = makeSolidImage(color: .systemBlue).pngData()!
    try pngData.write(to: fileURL)

    let loader = makeLoader()
    let result = try await loader.loadImageResult(for: FKImageLoadRequest(url: fileURL))

    XCTAssertFalse(result.wasCached)
    XCTAssertEqual(result.image.size, CGSize(width: 8, height: 8))
  }

  func testCacheOnlyPolicyFailsWhenEntryMissing() async {
    let loader = makeLoader()
    let request = FKImageLoadRequest(url: URL(string: "https://image-loader.test/uncached.png")!)
    let options = FKImageLoadOptions(cachePolicy: .cacheOnly)

    do {
      _ = try await loader.loadImageResult(for: request, options: options)
      XCTFail("Expected cacheMissUnderCacheOnlyPolicy")
    } catch let error as FKImageLoaderError {
      XCTAssertEqual(error, .cacheMissUnderCacheOnlyPolicy)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testReachabilityFastFailReturnsOffline() async {
    let loader = makeLoader(reachabilityChecker: { false })
    let request = FKImageLoadRequest(url: URL(string: "https://image-loader.test/photo.png")!)

    do {
      _ = try await loader.loadImageResult(for: request)
      XCTFail("Expected offline error")
    } catch let error as FKImageLoaderError {
      XCTAssertEqual(error, .offline)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testStoreAndCachedImageRoundTripInMemory() {
    let loader = makeLoader()
    let image = makeSolidImage(color: .systemGreen)
    let cacheKey = "round-trip-key"

    loader.store(image, forKey: cacheKey)

    XCTAssertNotNil(loader.cachedImage(forKey: cacheKey))
    XCTAssertEqual(loader.cachedImage(forKey: cacheKey)?.size, image.size)
  }

  func testLoadImageResultUsesMemoryCacheOnSecondFetch() async throws {
    let imageURL = URL(string: "https://image-loader.test/cached.png")!
    let pngData = makeSolidImage(color: .systemBlue).pngData()!
    StubImageURLProtocol.nextResponse = (
      pngData,
      HTTPURLResponse(
        url: imageURL,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "image/png"]
      )
    )

    let loader = makeLoader(useStubProtocol: true)
    let request = FKImageLoadRequest(url: imageURL)

    let first = try await loader.loadImageResult(for: request)
    let second = try await loader.loadImageResult(for: request)

    XCTAssertFalse(first.wasCached)
    XCTAssertTrue(second.wasCached)
  }

  func testOnEventReportsMemoryCacheHitOnSecondFetch() async throws {
    let imageURL = URL(string: "https://image-loader.test/cached-events.png")!
    let pngData = makeSolidImage(color: .systemRed).pngData()!
    StubImageURLProtocol.nextResponse = (
      pngData,
      HTTPURLResponse(
        url: imageURL,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "image/png"]
      )
    )

    let collector = ImageLoaderEventCollector()
    var configuration = FKImageLoaderConfiguration(
      memoryCostLimit: 8 * 1024 * 1024,
      memoryCountLimit: 20,
      diskSizeLimit: 8 * 1024 * 1024,
      reachabilityFastFail: false,
      diskCacheDirectoryURL: tempDirectory,
      isLoggingEnabled: false,
      onEvent: { collector.append($0) }
    )
    configuration.urlSessionProvider = {
      let sessionConfiguration = URLSessionConfiguration.ephemeral
      sessionConfiguration.protocolClasses = [StubImageURLProtocol.self]
      return URLSession(configuration: sessionConfiguration)
    }
    let loader = FKImageLoader(configuration: configuration)
    let request = FKImageLoadRequest(url: imageURL)

    _ = try await loader.loadImageResult(for: request)
    _ = try await loader.loadImageResult(for: request)

    XCTAssertTrue(collector.snapshot().contains(.fetchStarted))
    XCTAssertTrue(collector.snapshot().contains(where: {
      if case .fetchCompleted = $0 { return true }
      return false
    }))
    XCTAssertTrue(collector.snapshot().contains(.cacheHit(level: .memory)))
  }

  func testOnEventReportsFetchFailedForHTTPError() async {
    let imageURL = URL(string: "https://image-loader.test/failed-events.png")!
    StubImageURLProtocol.nextResponse = (
      Data(),
      HTTPURLResponse(url: imageURL, statusCode: 500, httpVersion: nil, headerFields: nil)
    )

    let collector = ImageLoaderEventCollector()
    var configuration = FKImageLoaderConfiguration(
      memoryCostLimit: 8 * 1024 * 1024,
      memoryCountLimit: 20,
      diskSizeLimit: 8 * 1024 * 1024,
      reachabilityFastFail: false,
      diskCacheDirectoryURL: tempDirectory,
      isLoggingEnabled: false,
      onEvent: { collector.append($0) }
    )
    configuration.urlSessionProvider = {
      let sessionConfiguration = URLSessionConfiguration.ephemeral
      sessionConfiguration.protocolClasses = [StubImageURLProtocol.self]
      return URLSession(configuration: sessionConfiguration)
    }
    let loader = FKImageLoader(configuration: configuration)

    do {
      _ = try await loader.loadImageResult(for: FKImageLoadRequest(url: imageURL))
      XCTFail("Expected httpStatus error")
    } catch {
      // expected
    }

    XCTAssertTrue(collector.snapshot().contains(.fetchStarted))
    XCTAssertTrue(collector.snapshot().contains(.fetchFailed))
  }

  func testTaskCancellationSurfacesCancelledError() async {
    let imageURL = URL(string: "https://image-loader.test/slow.png")!
    SlowImageURLProtocol.shouldDelay = true
    defer { SlowImageURLProtocol.shouldDelay = false }

    let loader = makeLoader(useSlowProtocol: true)
    let request = FKImageLoadRequest(url: imageURL)

    let task = Task {
      try await loader.loadImageResult(for: request)
    }
    try? await Task.sleep(nanoseconds: 50_000_000)
    task.cancel()

    do {
      _ = try await task.value
      XCTFail("Expected cancellation")
    } catch let error as FKImageLoaderError {
      XCTAssertEqual(error, .cancelled)
    } catch is CancellationError {
      // Structured cancellation is also acceptable before engine maps to FKImageLoaderError.
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testCancelLoadMarksInFlightWaiterAsCancelled() async {
    let imageURL = URL(string: "https://image-loader.test/slow-cancel.png")!
    SlowImageURLProtocol.shouldDelay = true
    defer { SlowImageURLProtocol.shouldDelay = false }

    let loader = makeLoader(useSlowProtocol: true)
    let request = FKImageLoadRequest(url: imageURL)

    let task = Task {
      try await loader.loadImageResult(for: request)
    }
    try? await Task.sleep(nanoseconds: 50_000_000)
    loader.cancelLoad(for: request)
    task.cancel()

    do {
      _ = try await task.value
      XCTFail("Expected cancellation")
    } catch let error as FKImageLoaderError {
      XCTAssertEqual(error, .cancelled)
    } catch is CancellationError {
      // acceptable
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  // MARK: - Helpers

  private func makeLoader(
    useStubProtocol: Bool = false,
    useSlowProtocol: Bool = false,
    reachabilityChecker: (@Sendable () -> Bool)? = nil
  ) -> FKImageLoader {
    var configuration = FKImageLoaderConfiguration(
      memoryCostLimit: 8 * 1024 * 1024,
      memoryCountLimit: 20,
      diskSizeLimit: 8 * 1024 * 1024,
      reachabilityFastFail: reachabilityChecker != nil,
      diskCacheDirectoryURL: tempDirectory,
      isLoggingEnabled: false,
      reachabilityChecker: reachabilityChecker
    )
    if useStubProtocol {
      configuration.urlSessionProvider = {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [StubImageURLProtocol.self]
        return URLSession(configuration: sessionConfiguration)
      }
    } else if useSlowProtocol {
      configuration.urlSessionProvider = {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [SlowImageURLProtocol.self]
        return URLSession(configuration: sessionConfiguration)
      }
    }
    return FKImageLoader(configuration: configuration)
  }

  private func makeSolidImage(color: UIColor) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
    return renderer.image { context in
      color.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    }
  }
}

// MARK: - Stub URLProtocol

private final class StubImageURLProtocol: URLProtocol {
  nonisolated(unsafe) static var nextResponse: (Data?, HTTPURLResponse?)?

  static func reset() {
    nextResponse = nil
  }

  override class func canInit(with request: URLRequest) -> Bool {
    request.url?.host == "image-loader.test"
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let client else { return }
    guard let nextResponse = Self.nextResponse else {
      client.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }
    if let response = nextResponse.1 {
      client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }
    if let data = nextResponse.0 {
      client.urlProtocol(self, didLoad: data)
    }
    client.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}

private final class SlowImageURLProtocol: URLProtocol {
  nonisolated(unsafe) static var shouldDelay = false

  override class func canInit(with request: URLRequest) -> Bool {
    request.url?.host == "image-loader.test"
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let client else { return }
    let pngData = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { ctx in
      UIColor.gray.setFill()
      ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    }.pngData() ?? Data()
    let response = HTTPURLResponse(
      url: request.url!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: ["Content-Type": "image/png"]
    )!

    if Self.shouldDelay {
      DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
        guard let self else { return }
        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: pngData)
        client.urlProtocolDidFinishLoading(self)
      }
      return
    }

    client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client.urlProtocol(self, didLoad: pngData)
    client.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}

private final class ImageLoaderEventCollector: @unchecked Sendable {
  private let lock = NSLock()
  private var events: [FKImageLoaderEvent] = []

  func append(_ event: FKImageLoaderEvent) {
    lock.lock()
    events.append(event)
    lock.unlock()
  }

  func snapshot() -> [FKImageLoaderEvent] {
    lock.lock()
    defer { lock.unlock() }
    return events
  }
}
