import Foundation

#if canImport(UIKit)
  import UIKit
#endif

/// Runtime configuration for ``FKImageLoader``.
///
/// Apply updates through ``FKImageLoader/configuration`` or ``FKImageLoader/apply(_:)``.
public struct FKImageLoaderConfiguration: Sendable, Equatable {
  /// Total cost limit for the in-memory cache (RGBA byte estimate).
  public var memoryCostLimit: Int
  /// Maximum number of images held in memory.
  public var memoryCountLimit: Int
  /// Maximum on-disk cache size in bytes.
  public var diskSizeLimit: Int
  /// Optional maximum age for disk entries; `nil` disables TTL enforcement.
  public var diskEntryTTL: TimeInterval?
  /// When `false`, cache reads and writes are skipped.
  public var isCachingEnabled: Bool
  /// Per-request timeout passed to `URLRequest`.
  public var requestTimeout: TimeInterval
  /// Upper bound on concurrent decode operations.
  public var maxConcurrentDecodes: Int
  /// Upper bound on concurrent prefetch operations.
  public var maxConcurrentPrefetches: Int
  /// When `true`, ``FKImageLoader`` fails fast with ``FKImageLoaderError/offline`` when
  /// ``reachabilityChecker`` returns `false`.
  public var reachabilityFastFail: Bool
  /// Default HTTP headers merged into every remote request.
  public var defaultHeaders: [String: String]
  /// Override directory for disk cache; `nil` uses `Caches/FKImageLoader/DiskCache/`.
  ///
  /// Changing this after initialization has no effect; set before creating ``FKImageLoader``.
  public var diskCacheDirectoryURL: URL?
  /// When `true`, ``FKImageLoader/cachedImage(for:)`` may read disk synchronously.
  public var allowsSynchronousDiskCacheRead: Bool
  /// `URLRequest` cache policy for remote loads.
  public var requestCachePolicy: URLRequest.CachePolicy
  /// Screen scale applied when decoding and downsampling.
  public var screenScale: Double
  /// Settings used to build or rebuild the internal `URLSession`.
  public var urlSessionSettings: FKImageLoaderURLSessionSettings
  /// When non-`nil`, replaces the internally created `URLSession` entirely.
  public var urlSessionProvider: (@Sendable () -> URLSession)?
  /// When `true`, emits debug lines through ``FKCoreKit/logger``.
  public var isLoggingEnabled: Bool
  /// When `true`, sends `If-None-Match` / `If-Modified-Since` for disk-backed remote loads.
  public var enablesConditionalGET: Bool
  /// When `true`, rejects `file://` URLs that resolve through symlinks.
  public var validatesFileURLs: Bool
  /// Delay before persisting disk index after access-only updates.
  public var diskIndexPersistDelay: TimeInterval
  /// Optional reachability hook; ignored unless ``reachabilityFastFail`` is `true`.
  public var reachabilityChecker: (@Sendable () -> Bool)?
  /// Optional metrics callback; `nil` adds zero overhead.
  public var onEvent: (@Sendable (FKImageLoaderEvent) -> Void)?

  /// Default production-oriented limits.
  public static let defaultMemoryCostLimit = 100 * 1024 * 1024
  /// Default in-memory entry count cap.
  public static let defaultMemoryCountLimit = 200
  /// Default on-disk cache budget.
  public static let defaultDiskSizeLimit = 200 * 1024 * 1024
  /// Default disk entry TTL (seven days).
  public static let defaultDiskEntryTTL: TimeInterval = 7 * 24 * 60 * 60

  /// Creates a configuration with FKKit defaults.
  public init(
    memoryCostLimit: Int = Self.defaultMemoryCostLimit,
    memoryCountLimit: Int = Self.defaultMemoryCountLimit,
    diskSizeLimit: Int = Self.defaultDiskSizeLimit,
    diskEntryTTL: TimeInterval? = Self.defaultDiskEntryTTL,
    isCachingEnabled: Bool = true,
    requestTimeout: TimeInterval = 60,
    maxConcurrentDecodes: Int = 4,
    maxConcurrentPrefetches: Int = 4,
    reachabilityFastFail: Bool = false,
    defaultHeaders: [String: String] = [:],
    diskCacheDirectoryURL: URL? = nil,
    allowsSynchronousDiskCacheRead: Bool = false,
    requestCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    screenScale: Double? = nil,
    urlSessionSettings: FKImageLoaderURLSessionSettings? = nil,
    urlSessionProvider: (@Sendable () -> URLSession)? = nil,
    isLoggingEnabled: Bool = false,
    enablesConditionalGET: Bool = true,
    validatesFileURLs: Bool = true,
    diskIndexPersistDelay: TimeInterval = 2,
    reachabilityChecker: (@Sendable () -> Bool)? = nil,
    onEvent: (@Sendable (FKImageLoaderEvent) -> Void)? = nil
  ) {
    self.memoryCostLimit = memoryCostLimit
    self.memoryCountLimit = memoryCountLimit
    self.diskSizeLimit = diskSizeLimit
    self.diskEntryTTL = diskEntryTTL
    self.isCachingEnabled = isCachingEnabled
    self.requestTimeout = requestTimeout
    self.maxConcurrentDecodes = max(1, maxConcurrentDecodes)
    self.maxConcurrentPrefetches = max(1, maxConcurrentPrefetches)
    self.reachabilityFastFail = reachabilityFastFail
    self.defaultHeaders = defaultHeaders
    self.diskCacheDirectoryURL = diskCacheDirectoryURL
    self.allowsSynchronousDiskCacheRead = allowsSynchronousDiskCacheRead
    self.requestCachePolicy = requestCachePolicy
    self.screenScale = screenScale ?? 0
    var sessionSettings = urlSessionSettings ?? FKImageLoaderURLSessionSettings()
    sessionSettings.timeoutIntervalForRequest = requestTimeout
    self.urlSessionSettings = sessionSettings
    self.urlSessionProvider = urlSessionProvider
    self.isLoggingEnabled = isLoggingEnabled
    self.enablesConditionalGET = enablesConditionalGET
    self.validatesFileURLs = validatesFileURLs
    self.diskIndexPersistDelay = max(0, diskIndexPersistDelay)
    self.reachabilityChecker = reachabilityChecker
    self.onEvent = onEvent
  }

  /// Compares equatable fields; callback properties are intentionally excluded.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.memoryCostLimit == rhs.memoryCostLimit
      && lhs.memoryCountLimit == rhs.memoryCountLimit
      && lhs.diskSizeLimit == rhs.diskSizeLimit
      && lhs.diskEntryTTL == rhs.diskEntryTTL
      && lhs.isCachingEnabled == rhs.isCachingEnabled
      && lhs.requestTimeout == rhs.requestTimeout
      && lhs.maxConcurrentDecodes == rhs.maxConcurrentDecodes
      && lhs.maxConcurrentPrefetches == rhs.maxConcurrentPrefetches
      && lhs.reachabilityFastFail == rhs.reachabilityFastFail
      && lhs.defaultHeaders == rhs.defaultHeaders
      && lhs.diskCacheDirectoryURL == rhs.diskCacheDirectoryURL
      && lhs.allowsSynchronousDiskCacheRead == rhs.allowsSynchronousDiskCacheRead
      && lhs.requestCachePolicy == rhs.requestCachePolicy
      && lhs.screenScale == rhs.screenScale
      && lhs.urlSessionSettings == rhs.urlSessionSettings
      && lhs.isLoggingEnabled == rhs.isLoggingEnabled
      && lhs.enablesConditionalGET == rhs.enablesConditionalGET
      && lhs.validatesFileURLs == rhs.validatesFileURLs
      && lhs.diskIndexPersistDelay == rhs.diskIndexPersistDelay
  }
}

#if canImport(UIKit)
  public extension FKImageLoaderConfiguration {
    /// Wires ``reachabilityFastFail`` to ``FKNetworkReachability/isReachable``.
    mutating func useNetworkReachability(_ provider: FKNetworkReachability) {
      let checker: @Sendable () -> Bool = { provider.isReachable }
      reachabilityChecker = checker
      reachabilityFastFail = true
    }
  }
#endif
