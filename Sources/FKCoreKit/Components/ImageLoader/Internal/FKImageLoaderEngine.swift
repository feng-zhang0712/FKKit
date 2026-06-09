#if canImport(UIKit)
  import Foundation
  import UIKit

  /// Payload produced by a successful load pipeline.
  struct FKLoadedImage: @unchecked Sendable {
    let image: UIImage
    let sourceData: Data?
    let wasCached: Bool
  }

  /// Coordinates fetch, decode, cache, and in-flight deduplication.
  actor FKImageLoaderEngine {
    private struct SharedLoad {
      var task: Task<FKLoadedImage, Error>
      var waiterOrder: [UUID]
      var cancelledWaiters: Set<UUID>
    }

    private var configuration: FKImageLoaderConfiguration
    private let memoryCache: FKImageMemoryCache
    private let diskCache: FKImageDiskCache
    private var fetchSession: URLSession
    private let decodeQueue: OperationQueue
    private let fileQueue: DispatchQueue
    private var sharedLoads: [String: SharedLoad] = [:]
    private var activeDataTasks: [String: URLSessionDataTask] = [:]
    private var prefetchKeys: Set<String> = []

    init(
      configuration: FKImageLoaderConfiguration,
      memoryCache: FKImageMemoryCache,
      diskCache: FKImageDiskCache
    ) {
      self.configuration = configuration
      self.memoryCache = memoryCache
      self.diskCache = diskCache
      fetchSession = Self.makeSession(from: configuration)
      decodeQueue = OperationQueue()
      decodeQueue.maxConcurrentOperationCount = configuration.maxConcurrentDecodes
      decodeQueue.name = "com.fkkit.imageloader.decode"
      decodeQueue.qualityOfService = .userInitiated
      fileQueue = DispatchQueue(label: "com.fkkit.imageloader.file", qos: .utility)
      diskCache.setPersistDelay(configuration.diskIndexPersistDelay)
    }

    func updateConfiguration(_ configuration: FKImageLoaderConfiguration) {
      self.configuration = configuration
      memoryCache.applyLimits(
        costLimit: configuration.memoryCostLimit,
        countLimit: configuration.memoryCountLimit
      )
      decodeQueue.maxConcurrentOperationCount = configuration.maxConcurrentDecodes
      diskCache.setPersistDelay(configuration.diskIndexPersistDelay)
      fetchSession.invalidateAndCancel()
      fetchSession = Self.makeSession(from: configuration)
      enforceDiskLimits()
      FKImageLoaderLogging.debug(configuration, "Configuration updated; URLSession rebuilt")
    }

    func load(
      request: FKImageLoadRequest,
      cacheKey: String,
      options: FKImageLoadOptions,
      waiterID: UUID
    ) async throws -> FKLoadedImage {
      try validateTargetDimensions(request)
      try Task.checkCancellation()

      if configuration.reachabilityFastFail,
        let checker = configuration.reachabilityChecker,
        checker() == false
      {
        throw FKImageLoaderError.offline
      }

      let policy = options.cachePolicy

      if configuration.isCachingEnabled, policy != .reloadIgnoringCache {
        if let image = memoryCache.image(forKey: cacheKey) {
          emit(.cacheHit(level: .memory))
          FKImageLoaderLogging.debug(configuration, "Memory cache hit")
          let data = options.returnsSourceData
            ? diskCache.data(forKey: cacheKey, ttl: configuration.diskEntryTTL)
            : nil
          return FKLoadedImage(image: image, sourceData: data, wasCached: true)
        }
        if let data = diskCache.data(forKey: cacheKey, ttl: configuration.diskEntryTTL),
          let image = try? decodeSync(data: data, request: request)
        {
          memoryCache.store(image, forKey: cacheKey)
          emit(.cacheHit(level: .disk))
          FKImageLoaderLogging.debug(configuration, "Disk cache hit")
          return FKLoadedImage(
            image: image,
            sourceData: options.returnsSourceData ? data : nil,
            wasCached: true
          )
        }
      }

      if policy == .cacheOnly {
        throw FKImageLoaderError.cacheMissUnderCacheOnlyPolicy
      }

      let sharedTask = registerWaiter(forKey: cacheKey, waiterID: waiterID, request: request, options: options)
      defer { endWaiter(waiterID, forKey: cacheKey) }

      do {
        let loaded = try await sharedTask.value
        try Task.checkCancellation()
        if isWaiterCancelled(waiterID, forKey: cacheKey) {
          throw FKImageLoaderError.cancelled
        }
        return loaded
      } catch is CancellationError {
        throw FKImageLoaderError.cancelled
      } catch let error as FKImageLoaderError {
        throw error
      } catch {
        throw FKImageLoaderError.network(underlyingDescription: error.localizedDescription)
      }
    }

    func cancelWaiter(forKey cacheKey: String, waiterID: UUID) {
      markWaiterCancelled(waiterID, forKey: cacheKey)
      FKImageLoaderLogging.debug(configuration, "Cancelled waiter for cache key")
    }

    func cancelLatestWaiter(forKey cacheKey: String) {
      guard var shared = sharedLoads[cacheKey] else { return }
      guard let latest = shared.waiterOrder.last(where: { !shared.cancelledWaiters.contains($0) }) else {
        return
      }
      shared.cancelledWaiters.insert(latest)
      sharedLoads[cacheKey] = shared
      abortSharedLoadIfNeeded(forKey: cacheKey)
    }

    func prefetchBatch(
      requests: [FKImageLoadRequest],
      options: FKImageLoadOptions
    ) async {
      await withTaskGroup(of: Void.self) { group in
        for request in requests {
          group.addTask {
            let cacheKey = FKImageCacheKeyBuilder.cacheKey(for: request)
            await self.prefetch(request: request, cacheKey: cacheKey, options: options)
          }
        }
      }
    }

    func prefetch(
      request: FKImageLoadRequest,
      cacheKey: String,
      options: FKImageLoadOptions
    ) async {
      prefetchKeys.insert(cacheKey)
      defer { prefetchKeys.remove(cacheKey) }
      let waiterID = UUID()
      _ = try? await load(
        request: request,
        cacheKey: cacheKey,
        options: options,
        waiterID: waiterID
      )
    }

    func cancelPrefetch(forKey cacheKey: String) {
      prefetchKeys.remove(cacheKey)
      cancelLatestWaiter(forKey: cacheKey)
      FKImageLoaderLogging.debug(configuration, "Cancelled prefetch")
    }

    func storeEncodedData(_ data: Data, forKey key: String) {
      guard configuration.isCachingEnabled else { return }
      diskCache.store(data, forKey: key)
      enforceDiskLimits()
    }

    func removeImage(forKey key: String) {
      memoryCache.removeImage(forKey: key)
      diskCache.removeImage(forKey: key)
    }

    func removeAllImages() {
      memoryCache.removeAllImages()
      diskCache.removeAllImages()
    }

    func clearMemoryCache() {
      memoryCache.clearAll()
    }

    func trimMemoryCache(toCost: Int) {
      memoryCache.trim(toCost: toCost)
    }

    func enforceDiskLimits() {
      let removed = diskCache.enforceLimits(
        sizeLimit: configuration.diskSizeLimit,
        ttl: configuration.diskEntryTTL
      )
      if removed > 0 {
        emit(.evicted(count: removed))
        FKImageLoaderLogging.debug(configuration, "Evicted \(removed) disk entries")
      }
    }

    func statistics() -> FKImageLoaderStatistics {
      let memory = memoryCache.statistics()
      let disk = diskCache.statistics()
      return FKImageLoaderStatistics(
        memoryEntryCount: memory.entryCount,
        memoryCostBytes: memory.costBytes,
        diskEntryCount: disk.entryCount,
        diskByteCount: disk.byteCount,
        inFlightLoadCount: sharedLoads.count,
        activePrefetchCount: prefetchKeys.count
      )
    }

    func flushDiskIndex() {
      diskCache.flushPendingIndexWrites()
    }

    // MARK: - Private

    private static func makeSession(from configuration: FKImageLoaderConfiguration) -> URLSession {
      if let provider = configuration.urlSessionProvider {
        return provider()
      }
      var settings = configuration.urlSessionSettings
      settings.timeoutIntervalForRequest = configuration.requestTimeout
      return URLSession(configuration: settings.makeConfiguration())
    }

    private func registerWaiter(
      forKey cacheKey: String,
      waiterID: UUID,
      request: FKImageLoadRequest,
      options: FKImageLoadOptions
    ) -> Task<FKLoadedImage, Error> {
      if var existing = sharedLoads[cacheKey] {
        existing.waiterOrder.append(waiterID)
        sharedLoads[cacheKey] = existing
        return existing.task
      }
      let task = Task { try await self.performFetchAndDecode(request: request, cacheKey: cacheKey, options: options) }
      sharedLoads[cacheKey] = SharedLoad(task: task, waiterOrder: [waiterID], cancelledWaiters: [])
      return task
    }

    private func endWaiter(_ waiterID: UUID, forKey cacheKey: String) {
      guard var shared = sharedLoads[cacheKey] else { return }
      shared.waiterOrder.removeAll { $0 == waiterID }
      shared.cancelledWaiters.remove(waiterID)
      if shared.waiterOrder.isEmpty {
        sharedLoads.removeValue(forKey: cacheKey)
      } else {
        sharedLoads[cacheKey] = shared
      }
    }

    private func markWaiterCancelled(_ waiterID: UUID, forKey cacheKey: String) {
      guard var shared = sharedLoads[cacheKey] else { return }
      shared.cancelledWaiters.insert(waiterID)
      sharedLoads[cacheKey] = shared
      abortSharedLoadIfNeeded(forKey: cacheKey)
    }

    private func isWaiterCancelled(_ waiterID: UUID, forKey cacheKey: String) -> Bool {
      sharedLoads[cacheKey]?.cancelledWaiters.contains(waiterID) ?? false
    }

    private func abortSharedLoadIfNeeded(forKey cacheKey: String) {
      guard let shared = sharedLoads[cacheKey] else { return }
      let hasActiveWaiters = shared.waiterOrder.contains { !shared.cancelledWaiters.contains($0) }
      guard !hasActiveWaiters else { return }
      shared.task.cancel()
      activeDataTasks[cacheKey]?.cancel()
      activeDataTasks.removeValue(forKey: cacheKey)
      sharedLoads.removeValue(forKey: cacheKey)
    }

    private func performFetchAndDecode(
      request: FKImageLoadRequest,
      cacheKey: String,
      options: FKImageLoadOptions
    ) async throws -> FKLoadedImage {
      let started = Date()
      emit(.fetchStarted)
      FKImageLoaderLogging.debug(configuration, "Fetch started")

      do {
        let payload = try await fetchPayload(for: request, cacheKey: cacheKey)
        try Task.checkCancellation()
        let image = try await decode(data: payload.data, request: request)
        if configuration.isCachingEnabled {
          memoryCache.store(image, forKey: cacheKey)
          if !options.excludesFromDiskCache {
            diskCache.store(payload.data, forKey: cacheKey, metadata: payload.metadata)
            enforceDiskLimits()
          }
        }
        emit(.fetchCompleted(duration: Date().timeIntervalSince(started)))
        FKImageLoaderLogging.debug(configuration, "Fetch completed")
        return FKLoadedImage(
          image: image,
          sourceData: options.returnsSourceData ? payload.data : nil,
          wasCached: false
        )
      } catch {
        emit(.fetchFailed)
        sharedLoads.removeValue(forKey: cacheKey)
        activeDataTasks.removeValue(forKey: cacheKey)
        FKImageLoaderLogging.debug(configuration, "Fetch failed: \(error)")
        throw error
      }
    }

    private struct FetchPayload: Sendable {
      let data: Data
      let metadata: FKImageDiskCacheMetadata
    }

    private func fetchPayload(for request: FKImageLoadRequest, cacheKey: String) async throws -> FetchPayload {
      let url = request.url
      let scheme = url.scheme?.lowercased() ?? ""
      switch scheme {
      case "file":
        let data = try await readLocalFile(at: url)
        return FetchPayload(data: data, metadata: .init())
      case "http", "https":
        return try await fetchRemotePayload(for: request, cacheKey: cacheKey)
      default:
        throw FKImageLoaderError.unsupportedURLScheme(scheme)
      }
    }

    private func readLocalFile(at url: URL) async throws -> Data {
      let validatesFileURLs = configuration.validatesFileURLs
      return try await withCheckedThrowingContinuation { continuation in
        fileQueue.async {
          do {
            let data = try Self.readLocalFileSync(at: url, validatesFileURLs: validatesFileURLs)
            continuation.resume(returning: data)
          } catch let error as FKImageLoaderError {
            continuation.resume(throwing: error)
          } catch {
            continuation.resume(throwing: FKImageLoaderError.fileReadFailed)
          }
        }
      }
    }

    private static func readLocalFileSync(at url: URL, validatesFileURLs: Bool) throws -> Data {
      guard url.isFileURL else {
        throw FKImageLoaderError.fileNotFound
      }
      if validatesFileURLs {
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
        if values.isSymbolicLink == true {
          throw FKImageLoaderError.insecureFileURL
        }
      }
      guard FileManager.default.fileExists(atPath: url.path) else {
        throw FKImageLoaderError.fileNotFound
      }
      return try Data(contentsOf: url)
    }

    private func fetchRemotePayload(for request: FKImageLoadRequest, cacheKey: String) async throws -> FetchPayload {
      var urlRequest = URLRequest(
        url: request.url,
        cachePolicy: configuration.requestCachePolicy,
        timeoutInterval: configuration.requestTimeout
      )
      for (key, value) in configuration.defaultHeaders {
        urlRequest.setValue(value, forHTTPHeaderField: key)
      }

      let ttl = configuration.diskEntryTTL
      let enablesConditionalGET = configuration.enablesConditionalGET && configuration.isCachingEnabled
      let diskCache = self.diskCache

      if enablesConditionalGET, let metadata = diskCache.metadata(forKey: cacheKey, ttl: ttl) {
        if let etag = metadata.etag {
          urlRequest.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        if let lastModified = metadata.lastModified {
          urlRequest.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
      }

      return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
          let task = fetchSession.dataTask(with: urlRequest) { data, response, error in
            Task { await self.clearDataTask(forKey: cacheKey) }
            if let error {
              continuation.resume(
                throwing: FKImageLoaderError.network(underlyingDescription: error.localizedDescription)
              )
              return
            }
            guard let http = response as? HTTPURLResponse else {
              continuation.resume(
                throwing: FKImageLoaderError.network(underlyingDescription: "Invalid response")
              )
              return
            }

            if http.statusCode == 304 {
              guard let cachedData = diskCache.data(forKey: cacheKey, ttl: ttl) else {
                continuation.resume(throwing: FKImageLoaderError.notModifiedWithoutCache)
                return
              }
              let metadata = diskCache.metadata(forKey: cacheKey, ttl: ttl) ?? FKImageDiskCacheMetadata()
              continuation.resume(returning: FetchPayload(data: cachedData, metadata: metadata))
              return
            }

            guard (200 ... 299).contains(http.statusCode) else {
              continuation.resume(throwing: FKImageLoaderError.httpStatus(code: http.statusCode))
              return
            }
            guard let data else {
              continuation.resume(throwing: FKImageLoaderError.decodeFailed)
              return
            }
            let metadata = FKImageDiskCacheMetadata(
              etag: http.value(forHTTPHeaderField: "ETag"),
              lastModified: http.value(forHTTPHeaderField: "Last-Modified")
            )
            continuation.resume(returning: FetchPayload(data: data, metadata: metadata))
          }
          Task { await self.storeDataTask(task, forKey: cacheKey) }
          task.resume()
        }
      } onCancel: {
        Task { await self.cancelRemoteFetch(forKey: cacheKey) }
      }
    }

    private func storeDataTask(_ task: URLSessionDataTask, forKey cacheKey: String) {
      activeDataTasks[cacheKey] = task
    }

    private func clearDataTask(forKey cacheKey: String) {
      activeDataTasks.removeValue(forKey: cacheKey)
    }

    private func cancelRemoteFetch(forKey cacheKey: String) {
      activeDataTasks[cacheKey]?.cancel()
      activeDataTasks.removeValue(forKey: cacheKey)
    }

    private func decodeSync(data: Data, request: FKImageLoadRequest) throws -> UIImage {
      try FKImageDecoder.decode(
        data: data,
        targetWidth: request.targetWidth,
        targetHeight: request.targetHeight,
        scale: CGFloat(configuration.screenScale)
      )
    }

    private func decode(data: Data, request: FKImageLoadRequest) async throws -> UIImage {
      let scale = CGFloat(configuration.screenScale)
      return try await withCheckedThrowingContinuation { continuation in
        decodeQueue.addOperation {
          do {
            let image = try FKImageDecoder.decode(
              data: data,
              targetWidth: request.targetWidth,
              targetHeight: request.targetHeight,
              scale: scale
            )
            continuation.resume(returning: image)
          } catch let error as FKImageLoaderError {
            continuation.resume(throwing: error)
          } catch {
            continuation.resume(throwing: FKImageLoaderError.decodeFailed)
          }
        }
      }
    }

    private func validateTargetDimensions(_ request: FKImageLoadRequest) throws {
      if let width = request.targetWidth, width <= 0 {
        throw FKImageLoaderError.invalidTargetDimensions
      }
      if let height = request.targetHeight, height <= 0 {
        throw FKImageLoaderError.invalidTargetDimensions
      }
    }

    private func emit(_ event: FKImageLoaderEvent) {
      configuration.onEvent?(event)
    }
  }
#endif
