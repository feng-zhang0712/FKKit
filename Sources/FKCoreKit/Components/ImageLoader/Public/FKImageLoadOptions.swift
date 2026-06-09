import Foundation

/// Cache behavior for a single ``FKImageLoader`` load invocation.
public enum FKImageLoadCachePolicy: Sendable, Equatable {
  /// Memory → disk → network (default).
  case `default`
  /// Skip memory and disk reads; still writes after a successful fetch.
  case reloadIgnoringCache
  /// Return only when cached; otherwise fail with ``FKImageLoaderError/cacheMissUnderCacheOnlyPolicy``.
  case cacheOnly
}

/// Per-request options that extend ``FKImageLoadRequest`` without changing Pluggable types.
public struct FKImageLoadOptions: Sendable, Equatable {
  /// Cache lookup policy for this load.
  public var cachePolicy: FKImageLoadCachePolicy
  /// When `true`, the encoded source bytes are included in ``FKImageLoadResult/sourceData``.
  public var returnsSourceData: Bool
  /// When `true`, successful loads skip disk persistence (memory cache still applies).
  public var excludesFromDiskCache: Bool

  /// Creates load options.
  public init(
    cachePolicy: FKImageLoadCachePolicy = .default,
    returnsSourceData: Bool = false,
    excludesFromDiskCache: Bool = false
  ) {
    self.cachePolicy = cachePolicy
    self.returnsSourceData = returnsSourceData
    self.excludesFromDiskCache = excludesFromDiskCache
  }
}
