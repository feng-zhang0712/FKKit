import CoreGraphics
import Foundation

/// A single remote image warm-up target for list prefetching.
public struct FKListImagePrefetchRequest: Sendable, Equatable {
  public var url: URL
  public var targetSize: CGSize

  public init(url: URL, targetSize: CGSize) {
    self.url = url
    self.targetSize = targetSize
  }
}

/// Opt-in protocol for custom cell payloads consumed by ``FKListImagePrefetchHelper``.
public protocol FKListImagePrefetchProviding: Sendable {
  /// Remote images to prefetch when the row becomes a prefetch candidate.
  var listPrefetchImageRequests: [FKListImagePrefetchRequest] { get }
}
