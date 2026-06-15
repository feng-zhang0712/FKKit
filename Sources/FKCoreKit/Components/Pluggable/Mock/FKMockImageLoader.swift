import Foundation

#if canImport(UIKit)
import UIKit

/// Configurable ``FKImageLoading`` mock for offline UI tests and Examples.
@MainActor
public final class FKMockImageLoader: FKImageLoading {
  /// Fixed image returned on successful loads.
  public var stubImage: UIImage?
  /// When set, ``loadImage(for:)`` throws this error.
  public var stubError: Error?
  /// Number of ``loadImage(for:)`` invocations.
  public private(set) var loadCallCount = 0
  /// URLs passed to ``cancelLoad(for:)``.
  public private(set) var cancelledURLs: [URL] = []

  /// Creates a mock loader.
  ///
  /// - Parameters:
  ///   - stubImage: Image to return; defaults to a system placeholder when `nil`.
  ///   - stubError: Optional error thrown on every load.
  public init(stubImage: UIImage? = nil, stubError: Error? = nil) {
    self.stubImage = stubImage
    self.stubError = stubError
  }

  /// Returns the stub image or throws ``stubError``.
  public func loadImage(for request: FKImageLoadRequest) async throws -> UIImage {
    loadCallCount += 1
    if let stubError {
      throw stubError
    }
    if let stubImage {
      return stubImage
    }
    let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
    guard let image = UIImage(systemName: "photo", withConfiguration: config) else {
      return UIImage()
    }
    return image
  }

  /// Records cancellation requests for test assertions.
  public func cancelLoad(for request: FKImageLoadRequest) {
    cancelledURLs.append(request.url)
  }

  /// Resets invocation counters.
  public func reset() {
    loadCallCount = 0
    cancelledURLs = []
  }
}

#endif
