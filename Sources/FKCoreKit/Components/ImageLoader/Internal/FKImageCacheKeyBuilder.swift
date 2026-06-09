import Foundation

/// Builds stable cache keys for ``FKImageLoadRequest`` values.
enum FKImageCacheKeyBuilder {
  /// Resolves the effective cache key for a request.
  static func cacheKey(for request: FKImageLoadRequest) -> String {
    if let custom = request.cacheKey, !custom.isEmpty {
      return custom
    }
    var components = [request.url.absoluteString]
    if let width = request.targetWidth {
      components.append("w=\(formatDimension(width))")
    }
    if let height = request.targetHeight {
      components.append("h=\(formatDimension(height))")
    }
    return components.joined(separator: "|")
  }

  private static func formatDimension(_ value: Double) -> String {
    String(format: "%g", value)
  }
}
