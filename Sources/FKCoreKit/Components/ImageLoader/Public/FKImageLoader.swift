#if canImport(UIKit)
  import Foundation
  import UIKit

  /// Default production implementation of ``FKImageLoading`` and ``FKImageCaching``.
  ///
  /// Provides network/local fetch, decode, downsampling, memory+disk cache, deduplication, and cancellation.
  ///
  /// - Important: ``cancelLoad(for:)`` marks the loader-side waiter as cancelled but does **not** cancel
  ///   the caller's Swift `Task`. Pair explicit cancellation with `task.cancel()` or rely on structured
  ///   concurrency from ``loadImage(for:options:)`` / ``loadImageResult(for:options:)``.
  @MainActor
  public final class FKImageLoader: FKImageLoading, FKImageCaching {
    /// Shared process-wide loader with default configuration.
    public static let shared: FKImageLoader = FKImageLoader()

    /// Runtime configuration; updates propagate to internal caches and rebuild the URL session.
    public var configuration: FKImageLoaderConfiguration {
      didSet { applyConfigurationUpdate() }
    }

    private let memoryCache: FKImageMemoryCache
    private let diskCache: FKImageDiskCache
    private let engine: FKImageLoaderEngine
    private let memoryWarningObserver = FKImageLoaderMemoryWarningObserver()

    /// Creates a loader with the given configuration.
    public init(configuration: FKImageLoaderConfiguration = .init()) {
      let resolvedConfiguration = Self.resolvedConfiguration(from: configuration)
      self.configuration = resolvedConfiguration
      memoryCache = FKImageMemoryCache(
        costLimit: resolvedConfiguration.memoryCostLimit,
        countLimit: resolvedConfiguration.memoryCountLimit
      )
      let diskDirectory = Self.defaultDiskCacheDirectory(override: resolvedConfiguration.diskCacheDirectoryURL)
      do {
        diskCache = try FKImageDiskCache(
          directoryURL: diskDirectory,
          persistDelay: resolvedConfiguration.diskIndexPersistDelay
        )
      } catch {
        preconditionFailure("FKImageLoader could not create disk cache at \(diskDirectory.path): \(error)")
      }
      engine = FKImageLoaderEngine(
        configuration: resolvedConfiguration,
        memoryCache: memoryCache,
        diskCache: diskCache
      )
      memoryWarningObserver.install { [weak self] in
        Task { @MainActor in
          await self?.clearMemoryCache()
        }
      }
    }

    /// Applies a new configuration value.
    public func apply(_ configuration: FKImageLoaderConfiguration) {
      self.configuration = configuration
    }

    /// Applies a configuration mutation block.
    public func apply(_ block: (inout FKImageLoaderConfiguration) -> Void) {
      var next = configuration
      block(&next)
      configuration = next
    }

    // MARK: - FKImageLoading

    /// Loads and decodes an image for the given request.
    public func loadImage(for request: FKImageLoadRequest) async throws -> UIImage {
      try await loadImageResult(for: request).image
    }

    /// Loads and decodes an image with explicit cache policy options.
    public func loadImage(
      for request: FKImageLoadRequest,
      options: FKImageLoadOptions
    ) async throws -> UIImage {
      try await loadImageResult(for: request, options: options).image
    }

    /// Loads an image and returns metadata such as source bytes and cache provenance.
    public func loadImageResult(for request: FKImageLoadRequest) async throws -> FKImageLoadResult {
      try await loadImageResult(for: request, options: .init())
    }

    /// Loads an image with options and returns a detailed result payload.
    public func loadImageResult(
      for request: FKImageLoadRequest,
      options: FKImageLoadOptions
    ) async throws -> FKImageLoadResult {
      let cacheKey = FKImageCacheKeyBuilder.cacheKey(for: request)
      let waiterID = UUID()
      return try await withTaskCancellationHandler {
        let loaded = try await engine.load(
          request: request,
          cacheKey: cacheKey,
          options: options,
          waiterID: waiterID
        )
        return FKImageLoadResult(
          image: loaded.image,
          sourceData: loaded.sourceData,
          wasCached: loaded.wasCached
        )
      } onCancel: {
        Task { await self.engine.cancelWaiter(forKey: cacheKey, waiterID: waiterID) }
      }
    }

    /// Cancels the most recent in-flight waiter for the resolved cache key of `request`.
    ///
    /// Also cancel the caller's Swift `Task` when you need the awaiting call to throw promptly.
    public func cancelLoad(for request: FKImageLoadRequest) {
      let cacheKey = FKImageCacheKeyBuilder.cacheKey(for: request)
      Task { await engine.cancelLatestWaiter(forKey: cacheKey) }
    }

    // MARK: - FKImageCaching

    /// Returns a memory-cached image for `key`.
    public func cachedImage(forKey key: String) -> UIImage? {
      memoryCache.image(forKey: key)
    }

    /// Stores an image in the memory cache.
    public func store(_ image: UIImage, forKey key: String) {
      store(image, forKey: key, persistsToDisk: false)
    }

    /// Stores an image in the memory cache and optionally persists encoded bytes to disk.
    public func store(_ image: UIImage, forKey key: String, persistsToDisk: Bool) {
      guard configuration.isCachingEnabled else { return }
      memoryCache.store(image, forKey: key)
      guard persistsToDisk else { return }
      Task {
        guard let data = FKImageDecoder.encodedData(from: image) else { return }
        await engine.storeEncodedData(data, forKey: key)
      }
    }

    /// Removes one cache entry from memory and disk (fire-and-forget).
    public func removeImage(forKey key: String) {
      Task { await removeImage(forKey: key) }
    }

    /// Removes one cache entry and awaits completion.
    public func removeImage(forKey key: String) async {
      await engine.removeImage(forKey: key)
    }

    /// Clears memory and disk caches (fire-and-forget).
    public func removeAllImages() {
      Task { await removeAllImages() }
    }

    /// Clears memory and disk caches and awaits completion.
    public func removeAllImages() async {
      await engine.removeAllImages()
    }

    // MARK: - Convenience

    /// Returns a cached image for `request`, checking memory first and optionally disk.
    public func cachedImage(for request: FKImageLoadRequest) -> UIImage? {
      let cacheKey = FKImageCacheKeyBuilder.cacheKey(for: request)
      if let image = memoryCache.image(forKey: cacheKey) {
        return image
      }
      guard configuration.isCachingEnabled, configuration.allowsSynchronousDiskCacheRead else {
        return nil
      }
      guard let data = diskCache.data(forKey: cacheKey, ttl: configuration.diskEntryTTL) else {
        return nil
      }
      guard
        let image = try? FKImageDecoder.decode(
          data: data,
          targetWidth: request.targetWidth,
          targetHeight: request.targetHeight,
          scale: CGFloat(configuration.screenScale > 0 ? configuration.screenScale : Double(UIScreen.main.scale))
        )
      else { return nil }
      memoryCache.store(image, forKey: cacheKey)
      configuration.onEvent?(.cacheHit(level: .disk))
      return image
    }

    /// Clears the memory cache and restores configured limits.
    public func clearMemoryCache() async {
      await engine.clearMemoryCache()
    }

    /// Evicts memory entries down to `toCost` bytes and restores configured limits afterward.
    public func trimMemoryCache(toCost: Int) async {
      await engine.trimMemoryCache(toCost: toCost)
    }

    /// Evicts memory entries down to `toCost` bytes (fire-and-forget).
    public func trimMemoryCache(toCost: Int) {
      Task { await trimMemoryCache(toCost: toCost) }
    }

    /// Returns a snapshot of cache and in-flight loader state.
    public func cacheStatistics() async -> FKImageLoaderStatistics {
      await engine.statistics()
    }

    /// Persists any deferred disk index updates immediately.
    public func flushDiskCacheIndex() async {
      await engine.flushDiskIndex()
    }

    // MARK: - Prefetch

    /// Prefetches a single image into cache without returning it to the caller.
    public func prefetch(_ request: FKImageLoadRequest, options: FKImageLoadOptions = .init()) async {
      let cacheKey = FKImageCacheKeyBuilder.cacheKey(for: request)
      await engine.prefetch(request: request, cacheKey: cacheKey, options: options)
    }

    /// Prefetches multiple URLs concurrently with ``FKImageLoaderConfiguration/maxConcurrentPrefetches``.
    public func prefetch(
      urls: [URL],
      targetSize: CGSize? = nil,
      options: FKImageLoadOptions = .init()
    ) async {
      let limit = max(1, configuration.maxConcurrentPrefetches)
      guard !urls.isEmpty else { return }

      for batchStart in stride(from: 0, to: urls.count, by: limit) {
        let batchEnd = min(batchStart + limit, urls.count)
        let requests = urls[batchStart ..< batchEnd].map { url in
          FKImageLoadRequest(url: url, targetSize: targetSize)
        }
        await engine.prefetchBatch(requests: requests, options: options)
      }
    }

    /// Cancels an in-flight prefetch for `request`.
    public func cancelPrefetch(for request: FKImageLoadRequest) {
      let cacheKey = FKImageCacheKeyBuilder.cacheKey(for: request)
      Task { await engine.cancelPrefetch(forKey: cacheKey) }
    }

    // MARK: - Private

    private func applyConfigurationUpdate() {
      let resolved = Self.resolvedConfiguration(from: configuration)
      memoryCache.applyLimits(
        costLimit: resolved.memoryCostLimit,
        countLimit: resolved.memoryCountLimit
      )
      diskCache.setPersistDelay(resolved.diskIndexPersistDelay)
      Task { await engine.updateConfiguration(resolved) }
    }

    private static func resolvedConfiguration(from configuration: FKImageLoaderConfiguration) -> FKImageLoaderConfiguration {
      var resolved = configuration
      if resolved.screenScale <= 0 {
        resolved.screenScale = Double(UIScreen.main.scale)
      }
      resolved.urlSessionSettings.timeoutIntervalForRequest = resolved.requestTimeout
      return resolved
    }

    private static func defaultDiskCacheDirectory(override: URL?) -> URL {
      if let override { return override }
      let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
      return caches
        .appendingPathComponent("FKImageLoader", isDirectory: true)
        .appendingPathComponent("DiskCache", isDirectory: true)
    }
  }

  private final class FKImageLoaderMemoryWarningObserver: @unchecked Sendable {
    private var token: NSObjectProtocol?

    func install(handler: @escaping @Sendable () -> Void) {
      token = NotificationCenter.default.addObserver(
        forName: UIApplication.didReceiveMemoryWarningNotification,
        object: nil,
        queue: .main
      ) { _ in
        handler()
      }
    }

    deinit {
      if let token {
        NotificationCenter.default.removeObserver(token)
      }
    }
  }
#endif
