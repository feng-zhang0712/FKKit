import Foundation

private final class NetworkCompletionBox<T>: @unchecked Sendable {
  private let queue: DispatchQueue
  fileprivate let handler: (Result<T, NetworkError>) -> Void

  init(queue: DispatchQueue, handler: @escaping (Result<T, NetworkError>) -> Void) {
    self.queue = queue
    self.handler = handler
  }

  func deliver(_ result: Result<T, NetworkError>) {
    queue.async { self.handler(result) }
  }
}

private final class DataTaskContext: @unchecked Sendable {
  var taskId: Int = 0
}

private final class RequestBox<R: Requestable>: @unchecked Sendable {
  let value: R
  init(_ value: R) { self.value = value }
}

/// Core HTTP client: builds requests from ``Requestable``, runs interceptors and signing,
/// handles 401 token refresh, cache/dedup, optional SSL pinning and HTTP retry, and upload/download tasks.
///
/// Completions dispatch on ``FKNetworkConfiguration/callbackOnMainQueue`` by default.
public final class FKNetworkClient: NSObject, Networkable, URLSessionTaskDelegate, URLSessionDownloadDelegate, @unchecked Sendable {
  /// Shared client using ``FKNetworkConfiguration/shared``.
  public static let shared = FKNetworkClient()

  /// Runtime configuration source.
  private let config: FKNetworkConfiguration
  /// Backing URLSession used for delegate callbacks and default transport.
  private var urlSession: URLSession!
  /// Injectable transport used for data/upload/download tasks.
  private var transport: NetworkSession!
  /// Cache engine used by cache policies.
  private let cache: Cacheable
  /// Deduplicator for idempotent in-flight requests.
  private let deduplicator: FKRequestDeduplicator
  /// Queue used to dispatch client callbacks.
  private let callbackQueue: DispatchQueue
  /// Shared JSON decoder.
  private let decoder: JSONDecoder

  /// Upload progress handlers keyed by task identifier.
  private var uploadProgressHandlers: [Int: (Double) -> Void] = [:]
  /// Download progress handlers keyed by task identifier.
  private var downloadProgressHandlers: [Int: (Double) -> Void] = [:]
  /// Download completion handlers keyed by task identifier.
  private var downloadCompletions: [Int: (Result<(fileURL: URL, resumeData: Data?), NetworkError>) -> Void] = [:]
  /// Pinning failures keyed by task identifier.
  private var pinningFailureByTaskId: [Int: NetworkError] = [:]
  /// Lock guarding mutable handler maps.
  private var lock = NSLock()

  /// Creates a network client.
  ///
  /// - Parameters:
  ///   - config: Runtime network configuration.
  ///   - sessionConfiguration: URLSession configuration.
  ///   - transport: Optional custom transport. Defaults to a delegate-backed `URLSession`.
  ///   - cache: Cache implementation.
  ///   - deduplicator: In-flight deduplication helper.
  ///   - decoder: Decoder used for `Requestable.Response`.
  public init(
    config: FKNetworkConfiguration = .shared,
    sessionConfiguration: URLSessionConfiguration = .default,
    transport: NetworkSession? = nil,
    cache: Cacheable = FKNetworkCache(),
    deduplicator: FKRequestDeduplicator = .init(),
    decoder: JSONDecoder = .init()
  ) {
    self.config = config
    self.cache = cache
    self.deduplicator = deduplicator
    self.decoder = decoder
    callbackQueue = config.callbackOnMainQueue ? .main : .global(qos: .userInitiated)
    sessionConfiguration.timeoutIntervalForRequest = config.current?.timeout ?? 30
    super.init()
    urlSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    self.transport = transport ?? URLSessionAdapter(session: urlSession)
  }

  /// Sends a typed request using completion callback.
  @discardableResult
  public func send<R: Requestable>(
    _ request: R,
    completion: @escaping (Result<R.Response, NetworkError>) -> Void
  ) -> Cancellable {
    let resultBox = NetworkCompletionBox(queue: callbackQueue, handler: completion)

    if let provider = config.networkStatusProvider, provider.isReachable == false {
      resultBox.deliver(.failure(.offline))
      return NoopCancellable()
    }

    let baseRequest: URLRequest
    do {
      baseRequest = try buildBaseRequest(from: request)
    } catch let error as NetworkError {
      resultBox.deliver(.failure(error))
      return NoopCancellable()
    } catch {
      resultBox.deliver(.failure(.invalidURL))
      return NoopCancellable()
    }

    let key = cacheKey(for: baseRequest)

    if let ttl = request.cachePolicy.fk_cacheTTL, let data = cache.value(for: key) {
      decode(data: data, request: request, releaseDedup: {}, resultBox: resultBox)
      config.logger.log("cache hit(\(request.cachePolicy.fk_cacheLabel)), ttl: \(ttl), key: \(key)")
      return NoopCancellable()
    }

    let dedupKeyHeld: Bool
    if request.behavior == .idempotentDeduplicated {
      guard deduplicator.shouldProceed(key: key) else {
        resultBox.deliver(.failure(.businessError(code: -2, message: FKI18n.string("fkcore.network.error.request_deduplicated"))))
        return NoopCancellable()
      }
      dedupKeyHeld = true
    } else {
      dedupKeyHeld = false
    }

    let releaseDedup = { [deduplicator] in
      if dedupKeyHeld {
        deduplicator.complete(key: key)
      }
    }

    if config.enableMock, let mockData = request.mockData {
      decode(data: mockData, request: request, releaseDedup: releaseDedup, resultBox: resultBox)
      return NoopCancellable()
    }

    return executeDataTask(
      request: request,
      baseRequest: baseRequest,
      cacheKey: key,
      dedupKeyHeld: dedupKeyHeld,
      httpRetryCount: 0,
      tokenRetried: false,
      releaseDedup: releaseDedup,
      completion: completion
    )
  }

  /// Sends a typed request using async/await.
  @available(iOS 13.0, macOS 10.15, *)
  public func send<R: Requestable>(_ request: R) async throws -> R.Response {
    try await withCheckedThrowingContinuation { continuation in
      _ = send(request) { result in
        switch result {
        case let .success(value):
          continuation.resume(returning: value)
        case let .failure(error):
          continuation.resume(throwing: error)
        }
      }
    }
  }

  /// Performs a pluggable API request and returns raw transport metadata.
  ///
  /// Applies the same interceptor, 401 refresh, HTTP retry, and status-code rules as ``send(_:completion:)``.
  @discardableResult
  public func performAPIRequest(
    _ apiRequest: FKAPIRequest,
    completion: @escaping (Result<FKAPIResponse, NetworkError>) -> Void
  ) -> Cancellable {
    let resultBox = NetworkCompletionBox(queue: callbackQueue, handler: completion)

    if let provider = config.networkStatusProvider, provider.isReachable == false {
      resultBox.deliver(.failure(.offline))
      return NoopCancellable()
    }

    var request = URLRequest(url: apiRequest.url)
    request.httpMethod = apiRequest.method.rawValue
    if let timeout = apiRequest.timeout {
      request.timeoutInterval = timeout
    }
    apiRequest.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
    request.httpBody = apiRequest.body

    let finalized: URLRequest
    do {
      finalized = try finalizeRequest(request)
    } catch let error as NetworkError {
      resultBox.deliver(.failure(error))
      return NoopCancellable()
    } catch {
      resultBox.deliver(.failure(.signingFailed))
      return NoopCancellable()
    }

    return executeAPIRequest(
      apiRequest: apiRequest,
      request: finalized,
      httpRetryCount: 0,
      tokenRetried: false,
      resultBox: resultBox
    )
  }

  /// Async variant of ``performAPIRequest(_:completion:)``.
  @available(iOS 13.0, macOS 10.15, *)
  public func performAPIRequest(_ apiRequest: FKAPIRequest) async throws -> FKAPIResponse {
    try await withCheckedThrowingContinuation { continuation in
      _ = performAPIRequest(apiRequest) { result in
        continuation.resume(with: result)
      }
    }
  }

  @discardableResult
  public func upload(
    _ request: URLRequest,
    fileURL: URL,
    progress: ((Double) -> Void)?,
    completion: @escaping (Result<Data, NetworkError>) -> Void
  ) -> Cancellable {
    let resultBox = NetworkCompletionBox(queue: callbackQueue, handler: completion)
    let context = DataTaskContext()
    var task: URLSessionUploadTask!
    task = transport.uploadTask(with: request, fromFile: fileURL) { [weak self, context] data, response, error in
      guard let self else {
        resultBox.deliver(.failure(.underlying(NSError(domain: "FKNetworkClient", code: 0))))
        return
      }
      let result: Result<Data, NetworkError>
      if let error {
        result = .failure(self.mapError(error, taskId: context.taskId))
      } else if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        result = .failure(.serverError(statusCode: http.statusCode, message: nil))
      } else {
        result = .success(data ?? .init())
      }
      resultBox.deliver(result)
    }
    context.taskId = task.taskIdentifier
    if let progress {
      lock.lock()
      uploadProgressHandlers[task.taskIdentifier] = progress
      lock.unlock()
    }
    task.resume()
    return URLSessionTaskBox(task: task)
  }

  @discardableResult
  public func download(
    _ request: URLRequest,
    resumeData: Data?,
    progress: ((Double) -> Void)?,
    completion: @escaping (Result<(fileURL: URL, resumeData: Data?), NetworkError>) -> Void
  ) -> Cancellable {
    let task: URLSessionDownloadTask = if let resumeData {
      transport.downloadTask(withResumeData: resumeData)
    } else {
      transport.downloadTask(with: request)
    }
    if let progress {
      lock.lock()
      downloadProgressHandlers[task.taskIdentifier] = progress
      lock.unlock()
    }
    lock.lock()
    downloadCompletions[task.taskIdentifier] = completion
    lock.unlock()
    task.resume()
    return URLSessionTaskBox(task: task)
  }

  @discardableResult
  private func executeDataTask<R: Requestable>(
    request: R,
    baseRequest: URLRequest,
    cacheKey: String,
    dedupKeyHeld: Bool,
    httpRetryCount: Int,
    tokenRetried: Bool,
    releaseDedup: @escaping () -> Void,
    completion: @escaping (Result<R.Response, NetworkError>) -> Void
  ) -> Cancellable {
    let resultBox = NetworkCompletionBox(queue: callbackQueue, handler: completion)

    let finalized: URLRequest
    do {
      finalized = try finalizeRequest(baseRequest)
    } catch let error as NetworkError {
      releaseDedup()
      resultBox.deliver(.failure(error))
      return NoopCancellable()
    } catch {
      releaseDedup()
      resultBox.deliver(.failure(.signingFailed))
      return NoopCancellable()
    }

    let dedup = deduplicator
    let requestBox = RequestBox(request)
    let context = DataTaskContext()
    var task: URLSessionDataTask!
    task = transport.dataTask(with: finalized) { [weak self, context, requestBox] data, response, error in
      let finalizeDedup = {
        if dedupKeyHeld {
          dedup.complete(key: cacheKey)
        }
      }
      guard let self else {
        finalizeDedup()
        resultBox.deliver(.failure(.underlying(NSError(domain: "FKNetworkClient", code: 0, userInfo: [NSLocalizedDescriptionKey: FKI18n.string("fkcore.network.error.client_released")]))))
        return
      }
      self.handleResponse(
        requestBox: requestBox,
        baseRequest: baseRequest,
        cacheKey: cacheKey,
        dedupKeyHeld: dedupKeyHeld,
        data: data,
        response: response,
        error: error,
        taskId: context.taskId,
        httpRetryCount: httpRetryCount,
        tokenRetried: tokenRetried,
        releaseDedup: finalizeDedup,
        resultBox: resultBox
      )
    }
    context.taskId = task.taskIdentifier
    task.resume()
    return URLSessionTaskBox(task: task)
  }

  private func handleResponse<R: Requestable>(
    requestBox: RequestBox<R>,
    baseRequest: URLRequest,
    cacheKey: String,
    dedupKeyHeld: Bool,
    data: Data?,
    response: URLResponse?,
    error: Error?,
    taskId: Int,
    httpRetryCount: Int,
    tokenRetried: Bool,
    releaseDedup: @escaping () -> Void,
    resultBox: NetworkCompletionBox<R.Response>
  ) {
    if let error {
      let mapped = mapError(error, taskId: taskId)
      scheduleHTTPRetryIfNeeded(
        requestBox: requestBox,
        baseRequest: baseRequest,
        cacheKey: cacheKey,
        dedupKeyHeld: dedupKeyHeld,
        httpRetryCount: httpRetryCount,
        tokenRetried: tokenRetried,
        releaseDedup: releaseDedup,
        error: mapped,
        resultBox: resultBox
      )
      return
    }
    guard let httpResponse = response as? HTTPURLResponse else {
      releaseDedup()
      resultBox.deliver(.failure(.invalidResponse))
      return
    }
    guard var data else {
      releaseDedup()
      resultBox.deliver(.failure(.noData))
      return
    }
    do {
      for interceptor in config.responseInterceptors {
        data = try interceptor.intercept(data: data, response: httpResponse)
      }
    } catch {
      releaseDedup()
      resultBox.deliver(.failure(.underlying(error)))
      return
    }

    if httpResponse.statusCode == 401, tokenRetried == false {
      refreshTokenAndRetry(
        requestBox: requestBox,
        baseRequest: baseRequest,
        cacheKey: cacheKey,
        dedupKeyHeld: dedupKeyHeld,
        httpRetryCount: httpRetryCount,
        releaseDedup: releaseDedup,
        resultBox: resultBox
      )
      return
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let serverError = NetworkError.serverError(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8))
      scheduleHTTPRetryIfNeeded(
        requestBox: requestBox,
        baseRequest: baseRequest,
        cacheKey: cacheKey,
        dedupKeyHeld: dedupKeyHeld,
        httpRetryCount: httpRetryCount,
        tokenRetried: tokenRetried,
        releaseDedup: releaseDedup,
        error: serverError,
        resultBox: resultBox
      )
      return
    }

    storeCacheIfNeeded(request: requestBox.value, data: data, for: cacheKey)
    decode(
      data: data,
      request: requestBox.value,
      releaseDedup: releaseDedup,
      resultBox: resultBox
    )
  }

  private func scheduleHTTPRetryIfNeeded<R: Requestable>(
    requestBox: RequestBox<R>,
    baseRequest: URLRequest,
    cacheKey: String,
    dedupKeyHeld: Bool,
    httpRetryCount: Int,
    tokenRetried: Bool,
    releaseDedup: @escaping () -> Void,
    error: NetworkError,
    resultBox: NetworkCompletionBox<R.Response>
  ) {
    let policy = config.retryPolicy
    guard FKNetworkRetryExecutor.isMethodRetryable(request: requestBox.value, policy: policy),
          FKNetworkRetryExecutor.shouldRetry(error: error, httpRetryCount: httpRetryCount, policy: policy) else {
      releaseDedup()
      if httpRetryCount >= policy.maxRetryCount, policy.maxRetryCount > 0 {
        resultBox.deliver(.failure(.retryExhausted(lastError: error)))
      } else {
        resultBox.deliver(.failure(error))
      }
      return
    }

    let nextAttempt = httpRetryCount + 1
    let delay = FKNetworkRetryExecutor.delay(forAttempt: nextAttempt, policy: policy)
    config.logger.log("retry attempt \(nextAttempt) after \(String(format: "%.2f", delay))s for \(baseRequest.httpMethod ?? "GET") \(baseRequest.url?.absoluteString ?? "")")

    DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self, requestBox] in
      guard let self else {
        releaseDedup()
        resultBox.deliver(.failure(.underlying(NSError(domain: "FKNetworkClient", code: 0))))
        return
      }
      _ = self.executeDataTask(
        request: requestBox.value,
        baseRequest: baseRequest,
        cacheKey: cacheKey,
        dedupKeyHeld: dedupKeyHeld,
        httpRetryCount: nextAttempt,
        tokenRetried: tokenRetried,
        releaseDedup: releaseDedup,
        completion: resultBox.handler
      )
    }
  }

  private func refreshTokenAndRetry<R: Requestable>(
    requestBox: RequestBox<R>,
    baseRequest: URLRequest,
    cacheKey: String,
    dedupKeyHeld: Bool,
    httpRetryCount: Int,
    releaseDedup: @escaping () -> Void,
    resultBox: NetworkCompletionBox<R.Response>
  ) {
    guard let refresher = config.tokenRefresher, let tokenStore = config.tokenStore else {
      releaseDedup()
      resultBox.deliver(.failure(.tokenRefreshFailed))
      return
    }
    refresher.refreshToken(using: tokenStore.refreshToken) { [weak self, requestBox] result in
      guard let self else {
        releaseDedup()
        resultBox.deliver(.failure(.tokenRefreshFailed))
        return
      }
      switch result {
      case let .success(token):
        tokenStore.accessToken = token
        var retryBase = baseRequest
        retryBase.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = self.executeDataTask(
          request: requestBox.value,
          baseRequest: retryBase,
          cacheKey: cacheKey,
          dedupKeyHeld: dedupKeyHeld,
          httpRetryCount: httpRetryCount,
          tokenRetried: true,
          releaseDedup: releaseDedup,
          completion: resultBox.handler
        )
      case .failure:
        releaseDedup()
        resultBox.deliver(.failure(.tokenRefreshFailed))
      }
    }
  }

  @discardableResult
  private func executeAPIRequest(
    apiRequest: FKAPIRequest,
    request: URLRequest,
    httpRetryCount: Int,
    tokenRetried: Bool,
    resultBox: NetworkCompletionBox<FKAPIResponse>
  ) -> Cancellable {
    let context = DataTaskContext()
    var task: URLSessionDataTask!
    task = transport.dataTask(with: request) { [weak self, context] data, response, error in
      guard let self else {
        resultBox.deliver(.failure(.underlying(NSError(domain: "FKNetworkClient", code: 0))))
        return
      }
      self.handleAPIResponse(
        apiRequest: apiRequest,
        request: request,
        data: data,
        response: response,
        error: error,
        taskId: context.taskId,
        httpRetryCount: httpRetryCount,
        tokenRetried: tokenRetried,
        resultBox: resultBox
      )
    }
    context.taskId = task.taskIdentifier
    task.resume()
    return URLSessionTaskBox(task: task)
  }

  private func handleAPIResponse(
    apiRequest: FKAPIRequest,
    request: URLRequest,
    data: Data?,
    response: URLResponse?,
    error: Error?,
    taskId: Int,
    httpRetryCount: Int,
    tokenRetried: Bool,
    resultBox: NetworkCompletionBox<FKAPIResponse>
  ) {
    if let error {
      let mapped = mapError(error, taskId: taskId)
      scheduleAPIRetryIfNeeded(
        apiRequest: apiRequest,
        request: request,
        httpRetryCount: httpRetryCount,
        tokenRetried: tokenRetried,
        error: mapped,
        resultBox: resultBox
      )
      return
    }
    guard let httpResponse = response as? HTTPURLResponse else {
      resultBox.deliver(.failure(.invalidResponse))
      return
    }
    guard var data else {
      resultBox.deliver(.failure(.noData))
      return
    }
    do {
      for interceptor in config.responseInterceptors {
        data = try interceptor.intercept(data: data, response: httpResponse)
      }
    } catch {
      resultBox.deliver(.failure(.underlying(error)))
      return
    }

    if httpResponse.statusCode == 401, tokenRetried == false {
      refreshAPIAndRetry(
        apiRequest: apiRequest,
        request: request,
        httpRetryCount: httpRetryCount,
        resultBox: resultBox
      )
      return
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let serverError = NetworkError.serverError(
        statusCode: httpResponse.statusCode,
        message: String(data: data, encoding: .utf8)
      )
      scheduleAPIRetryIfNeeded(
        apiRequest: apiRequest,
        request: request,
        httpRetryCount: httpRetryCount,
        tokenRetried: tokenRetried,
        error: serverError,
        resultBox: resultBox
      )
      return
    }

    resultBox.deliver(.success(FKAPIResponse(data: data, httpResponse: httpResponse)))
  }

  private func scheduleAPIRetryIfNeeded(
    apiRequest: FKAPIRequest,
    request: URLRequest,
    httpRetryCount: Int,
    tokenRetried: Bool,
    error: NetworkError,
    resultBox: NetworkCompletionBox<FKAPIResponse>
  ) {
    let policy = config.retryPolicy
    let method = HTTPMethod(rawValue: apiRequest.method.rawValue) ?? .get
    guard FKNetworkRetryExecutor.isHTTPMethodRetryable(method: method, isIdempotent: false, policy: policy),
          FKNetworkRetryExecutor.shouldRetry(error: error, httpRetryCount: httpRetryCount, policy: policy) else {
      if httpRetryCount >= policy.maxRetryCount, policy.maxRetryCount > 0 {
        resultBox.deliver(.failure(.retryExhausted(lastError: error)))
      } else {
        resultBox.deliver(.failure(error))
      }
      return
    }

    let nextAttempt = httpRetryCount + 1
    let delay = FKNetworkRetryExecutor.delay(forAttempt: nextAttempt, policy: policy)
    config.logger.log("retry attempt \(nextAttempt) after \(String(format: "%.2f", delay))s for \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")

    DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
      guard let self else {
        resultBox.deliver(.failure(.underlying(NSError(domain: "FKNetworkClient", code: 0))))
        return
      }
      _ = self.executeAPIRequest(
        apiRequest: apiRequest,
        request: request,
        httpRetryCount: nextAttempt,
        tokenRetried: tokenRetried,
        resultBox: resultBox
      )
    }
  }

  private func refreshAPIAndRetry(
    apiRequest: FKAPIRequest,
    request: URLRequest,
    httpRetryCount: Int,
    resultBox: NetworkCompletionBox<FKAPIResponse>
  ) {
    guard let refresher = config.tokenRefresher, let tokenStore = config.tokenStore else {
      resultBox.deliver(.failure(.tokenRefreshFailed))
      return
    }
    refresher.refreshToken(using: tokenStore.refreshToken) { [weak self] result in
      guard let self else {
        resultBox.deliver(.failure(.tokenRefreshFailed))
        return
      }
      switch result {
      case let .success(token):
        tokenStore.accessToken = token
        var retryRequest = request
        retryRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = self.executeAPIRequest(
          apiRequest: apiRequest,
          request: retryRequest,
          httpRetryCount: httpRetryCount,
          tokenRetried: true,
          resultBox: resultBox
        )
      case .failure:
        resultBox.deliver(.failure(.tokenRefreshFailed))
      }
    }
  }

  private func buildBaseRequest<R: Requestable>(from endpoint: R) throws -> URLRequest {
    guard let env = config.current else { throw NetworkError.invalidURL }
    guard var components = URLComponents(url: env.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
    else {
      throw NetworkError.invalidURL
    }
    let mergedQuery = config.commonQueryItems.merging(endpoint.queryItems) { _, latest in latest }
    if mergedQuery.isEmpty == false {
      components.queryItems = mergedQuery.map { .init(name: $0.key, value: $0.value) }.sorted(by: { $0.name < $1.name })
    }
    guard let finalURL = components.url else { throw NetworkError.invalidURL }

    var request = URLRequest(url: finalURL)
    request.httpMethod = endpoint.method.rawValue
    request.timeoutInterval = env.timeout

    let mergedHeaders = env.defaultHeaders.merging(endpoint.headers) { _, latest in latest }
    mergedHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

    if let rawBody = endpoint.rawBody {
      request.httpBody = rawBody
    } else {
      var payload = endpoint.bodyParameters
      if let encrypt = config.encryptParameters {
        do {
          payload = try encrypt(payload)
        } catch let error as NetworkError {
          throw error
        } catch {
          throw NetworkError.encryptionFailed
        }
      }
      switch endpoint.encoding {
      case .query:
        break
      case .json:
        if payload.isEmpty == false {
          request.httpBody = try JSONSerialization.data(withJSONObject: payload)
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
      case .formURLEncoded:
        if payload.isEmpty == false {
          let form = payload.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: "&")
          request.httpBody = form.data(using: .utf8)
          request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
      }
    }
    return request
  }

  private func finalizeRequest(_ request: URLRequest) throws -> URLRequest {
    var mutable = request
    for interceptor in config.requestInterceptors {
      mutable = try interceptor.intercept(mutable)
    }
    if let signer = config.signer {
      mutable = try signer.sign(mutable)
    }
    return mutable
  }

  private func decode<R: Requestable>(
    data: Data,
    request: R,
    releaseDedup: @escaping () -> Void,
    resultBox: NetworkCompletionBox<R.Response>
  ) {
    do {
      let value = try decoder.decode(R.Response.self, from: data)
      releaseDedup()
      resultBox.deliver(.success(value))
    } catch {
      releaseDedup()
      resultBox.deliver(.failure(.decodingFailed(underlying: error)))
    }
  }

  private func storeCacheIfNeeded<R: Requestable>(request: R, data: Data, for key: String) {
    switch request.cachePolicy {
    case .none:
      break
    case let .memory(ttl):
      cache.set(data, for: key, ttl: ttl, toDisk: false)
    case let .disk(ttl):
      cache.set(data, for: key, ttl: ttl, toDisk: true)
    case let .memoryAndDisk(ttl):
      cache.set(data, for: key, ttl: ttl, toDisk: true)
    }
  }

  private func cacheKey(for request: URLRequest) -> String {
    let body = request.httpBody?.base64EncodedString() ?? ""
    return "\(request.httpMethod ?? "GET")|\(request.url?.absoluteString ?? "")|\(body)"
  }

  private func mapError(_ error: Error, taskId: Int? = nil) -> NetworkError {
    if let taskId {
      lock.lock()
      let pinningFailure = pinningFailureByTaskId.removeValue(forKey: taskId)
      lock.unlock()
      if let pinningFailure {
        return pinningFailure
      }
    }

    let nsError = error as NSError
    if nsError.domain == NSURLErrorDomain {
      if nsError.code == NSURLErrorCancelled {
        return .requestCancelled
      }
      if nsError.code == NSURLErrorNotConnectedToInternet {
        return .offline
      }
      if nsError.code == NSURLErrorServerCertificateUntrusted {
        return .sslValidationFailed
      }
    }
    return .underlying(error)
  }

  public func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didSendBodyData bytesSent: Int64,
    totalBytesSent: Int64,
    totalBytesExpectedToSend: Int64
  ) {
    guard totalBytesExpectedToSend > 0 else { return }
    let value = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
    lock.lock()
    let handler = uploadProgressHandlers[task.taskIdentifier]
    lock.unlock()
    handler?(value)
  }

  public func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    guard totalBytesExpectedToWrite > 0 else { return }
    let value = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    lock.lock()
    let handler = downloadProgressHandlers[downloadTask.taskIdentifier]
    lock.unlock()
    handler?(value)
  }

  public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    lock.lock()
    let completion = downloadCompletions.removeValue(forKey: downloadTask.taskIdentifier)
    downloadProgressHandlers.removeValue(forKey: downloadTask.taskIdentifier)
    lock.unlock()
    callbackQueue.async {
      completion?(.success((fileURL: location, resumeData: nil)))
    }
  }

  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error else { return }
    lock.lock()
    let completion = downloadCompletions.removeValue(forKey: task.taskIdentifier)
    uploadProgressHandlers.removeValue(forKey: task.taskIdentifier)
    downloadProgressHandlers.removeValue(forKey: task.taskIdentifier)
    lock.unlock()

    let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
    let mappedError = mapError(error, taskId: task.taskIdentifier)
    callbackQueue.async {
      completion?(.failure(resumeData == nil ? mappedError : .underlying(error)))
    }
  }

  public func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
      completionHandler(.performDefaultHandling, nil)
      return
    }
    guard let trust = challenge.protectionSpace.serverTrust else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    let host = challenge.protectionSpace.host
    if let pinning = config.sslPinning, FKSSLPinningValidator.shouldPin(host: host, config: pinning) {
      do {
        try FKSSLPinningValidator.validate(trust: trust, host: host, config: pinning)
        completionHandler(.useCredential, URLCredential(trust: trust))
      } catch let error as NetworkError {
        if case .sslPinningFailed = error, pinning.allowUserTrustEvaluationFallback {
          completionHandler(.performDefaultHandling, nil)
          return
        }
        lock.lock()
        pinningFailureByTaskId[task.taskIdentifier] = error
        lock.unlock()
        completionHandler(.cancelAuthenticationChallenge, nil)
      } catch {
        lock.lock()
        pinningFailureByTaskId[task.taskIdentifier] = .sslPinningFailed(host: host)
        lock.unlock()
        completionHandler(.cancelAuthenticationChallenge, nil)
      }
      return
    }

    if let shouldPin = config.shouldPinSSLHost {
      if shouldPin(host) == false {
        completionHandler(.performDefaultHandling, nil)
        return
      }
      completionHandler(.useCredential, URLCredential(trust: trust))
      return
    }

    completionHandler(.performDefaultHandling, nil)
  }
}

private final class NoopCancellable: Cancellable {
  func cancel() {}
}

private extension NetworkCachePolicy {
  var fk_cacheTTL: TimeInterval? {
    switch self {
    case .none:
      return nil
    case let .memory(ttl), let .disk(ttl), let .memoryAndDisk(ttl):
      return ttl
    }
  }

  var fk_cacheLabel: String {
    switch self {
    case .none: return "none"
    case .memory: return "memory"
    case .disk: return "disk"
    case .memoryAndDisk: return "memory+disk"
    }
  }
}
