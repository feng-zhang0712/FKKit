import Foundation

/// Cache tier reported in loader metrics events.
public enum FKImageLoaderCacheLevel: Sendable, Equatable {
  /// In-process memory cache.
  case memory
  /// On-disk cache under the Caches directory.
  case disk
}

/// Optional metrics and debug events emitted by ``FKImageLoader``.
public enum FKImageLoaderEvent: Sendable, Equatable {
  /// A cached image was returned without network or disk I/O.
  case cacheHit(level: FKImageLoaderCacheLevel)
  /// A network or file fetch started for the resolved cache key.
  case fetchStarted
  /// A fetch completed successfully.
  case fetchCompleted(duration: TimeInterval)
  /// A fetch failed before a decoded image was produced.
  case fetchFailed
  /// Cache entries were evicted (memory trim or disk LRU).
  case evicted(count: Int)
}
