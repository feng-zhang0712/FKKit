import Foundation

#if canImport(UIKit)
  import UIKit

  public extension FKImageLoadRequest {
    /// Resolved cache key using the same formatting as ``FKImageLoader``.
    var resolvedCacheKey: String {
      FKImageCacheKeyBuilder.cacheKey(for: self)
    }
  }
#endif
