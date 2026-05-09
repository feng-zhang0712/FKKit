import UIKit
import FKCoreKit

/// Hands-on surface for `FKNetworkClient`: typed `Requestable` sends, interceptors, cache,
/// deduplication, mock mode, token refresh on `401`, uploads, downloads, and cancellation.
final class FKNetworkExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  /// Fixed log panel (same layout as `FKAsyncExampleViewController` / Permissions example).
  private let logView = UITextView()

  private let reachabilitySimulator = FKNetworkExampleReachabilitySimulator()
  private let tokenStore = FKNetworkExampleTokenStore()

  private let primaryConfig: FKNetworkConfiguration
  private let httpBinConfig: FKNetworkConfiguration

  private let jsonClient: FKNetworkClient
  private let httpBinClient: FKNetworkClient

  private var cancellableTask: Cancellable?
  private var uploadTask: Cancellable?
  private var downloadTask: Cancellable?
  private var storedResumeData: Data?

  private var mockModeEnabled = false

  init() {
    primaryConfig = Self.makeJSONPlaceholderConfiguration(reachability: reachabilitySimulator)
    httpBinConfig = Self.makeHTTPBinConfiguration(
      reachability: reachabilitySimulator,
      tokenStore: tokenStore
    )
    jsonClient = FKNetworkClient(config: primaryConfig)
    httpBinClient = FKNetworkClient(config: httpBinConfig)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKNetwork"
    view.backgroundColor = .systemBackground
    buildLayout()
    buildDemoButtons()
    appendLog("FKNetwork examples ready. Uses JSONPlaceholder + HTTPBin; requires outbound network for live demos.")
  }

  deinit {
    cancellableTask?.cancel()
    uploadTask?.cancel()
    downloadTask?.cancel()
  }

  // MARK: - Configuration factories

  private static func makeJSONPlaceholderConfiguration(
    reachability: FKNetworkExampleReachabilitySimulator
  ) -> FKNetworkConfiguration {
    let env = FKEnvironmentConfig(
      baseURL: URL(string: "https://jsonplaceholder.typicode.com")!,
      timeout: 25,
      defaultHeaders: ["Accept": "application/json"]
    )
    return FKNetworkConfiguration(
      environment: .development,
      environmentMap: [.development: env],
      commonQueryItems: ["source": "FKNetworkExample"],
      requestInterceptors: [],
      responseInterceptors: [
        FKNetworkExampleEnvelopeInterceptor(),
        JSONResponseInterceptor(),
      ],
      signer: nil,
      tokenStore: nil,
      tokenRefresher: nil,
      logger: FKDefaultNetworkLogger(),
      networkStatusProvider: reachability,
      enableMock: false,
      shouldPinSSLHost: nil,
      encryptParameters: nil,
      callbackOnMainQueue: true
    )
  }

  private static func makeHTTPBinConfiguration(
    reachability: FKNetworkExampleReachabilitySimulator,
    tokenStore: FKNetworkExampleTokenStore
  ) -> FKNetworkConfiguration {
    let env = FKEnvironmentConfig(
      baseURL: URL(string: "https://httpbin.org")!,
      timeout: 35,
      defaultHeaders: ["Accept": "application/json"]
    )
    return FKNetworkConfiguration(
      environment: .development,
      environmentMap: [.development: env],
      commonQueryItems: [:],
      requestInterceptors: [
        FKNetworkExampleTraceInterceptor(),
        AuthHeaderInterceptor(tokenStore: tokenStore),
      ],
      responseInterceptors: [JSONResponseInterceptor()],
      signer: MD5RequestSigner(secret: "fk-network-example-secret"),
      tokenStore: tokenStore,
      tokenRefresher: FKNetworkExampleDemoTokenRefresher(),
      logger: FKDefaultNetworkLogger(),
      networkStatusProvider: reachability,
      enableMock: false,
      shouldPinSSLHost: nil,
      encryptParameters: nil,
      callbackOnMainQueue: true
    )
  }

  // MARK: - Layout

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    contentStack.axis = .vertical
    contentStack.spacing = 8
    contentStack.translatesAutoresizingMaskIntoConstraints = false

    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.layer.cornerRadius = 8
    logView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.52),

      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      logView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func buildDemoButtons() {
    addSectionHeading("Toggles")
    addToggleRow(titleKey: \Self.offlineToggleTitle, action: #selector(toggleSimulatedOffline))
    addToggleRow(titleKey: \Self.mockToggleTitle, action: #selector(toggleMockMode))

    addSectionHeading("JSONPlaceholder — typed Requestable (completion)")
    addActionButton("GET /users/:id") { [weak self] in self?.runGETUser() }
    addActionButton("GET /posts (common query + endpoint query)") { [weak self] in self?.runMergedQueryPosts() }
    addActionButton("GET /posts (custom header)") { [weak self] in self?.runCustomHeaderPosts() }
    addActionButton("POST /posts (JSON body)") { [weak self] in self?.runPOSTJSON() }
    addActionButton("PUT /posts/1 (JSON replace)") { [weak self] in self?.runPUTPost() }
    addActionButton("PATCH /posts/1 (JSON partial)") { [weak self] in self?.runPATCHPost() }
    addActionButton("DELETE /posts/1 (empty JSON body)") { [weak self] in self?.runDELETEPost() }

    addSectionHeading("JSONPlaceholder — cache policies")
    addActionButton("Cache: memory TTL 60s — GET /users/1") { [weak self] in self?.runMemoryCacheUser() }
    addActionButton("Cache: disk TTL 60s — GET /users/1") { [weak self] in self?.runDiskCacheUser() }
    addActionButton("Cache: memory+disk TTL 120s — GET /users/1") { [weak self] in self?.runMemoryDiskCacheUser() }

    addSectionHeading("Deduplication & mock (JSONPlaceholder + HTTPBin)")
    addActionButton("Idempotent dedup: HTTPBin /delay/1 ×2 (second rejected while first runs)") { [weak self] in self?.runDedupPair() }
    addActionButton("Idempotent dedup: JSONPlaceholder GET /posts (non-deterministic if API is faster than scheduling)") { [weak self] in
      self?.runDedupJSONPlaceholderPair()
    }
    addActionButton("Mock: envelope JSON + response interceptor") { [weak self] in self?.runEnvelopeMockUser() }
    addActionButton("Mock: plain JSON (no envelope)") { [weak self] in self?.runPlainMockUser() }

    addSectionHeading("JSONPlaceholder — async/await")
    addActionButton("async/await GET /users/2") { [weak self] in self?.runAsyncAwaitUser() }

    addSectionHeading("HTTPBin — interceptors, signing, forms, auth")
    addActionButton("Reset tokens then GET /bearer (401 → refresh → retry)") { [weak self] in self?.runBearer401Flow() }
    addActionButton("GET /get (trace header + MD5 signer headers echoed)") { [weak self] in self?.runSignedGET() }
    addActionButton("POST /post (application/x-www-form-urlencoded)") { [weak self] in self?.runFormURLEncodedPOST() }

    addSectionHeading("HTTPBin — cancellable delay")
    addActionButton("GET /delay/2 then tap Cancel active") { [weak self] in self?.runDelayedGETForCancel() }

    addSectionHeading("Upload & download")
    addActionButton("Upload file with progress → POST https://httpbin.org/post") { [weak self] in self?.runUpload() }
    addActionButton("Download bytes with progress") { [weak self] in self?.runDownload() }
    addActionButton("Resume download (needs saved resume data)") { [weak self] in self?.resumeDownload() }

    addSectionHeading("Controls")
    addActionButton("Cancel active data task / upload / download") { [weak self] in self?.cancelActiveTasks() }
    addActionButton("Clear log") { [weak self] in self?.clearLogs() }
  }

  private func addSectionHeading(_ text: String) {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.text = text
    label.numberOfLines = 0
    label.textAlignment = .natural
    label.accessibilityTraits.insert(.header)
    contentStack.addArrangedSubview(label)
    contentStack.setCustomSpacing(12, after: label)
  }

  private func addActionButton(_ title: String, handler: @escaping () -> Void) {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.contentHorizontalAlignment = .leading
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.lineBreakMode = .byWordWrapping
    button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
    contentStack.addArrangedSubview(button)
  }

  private var offlineToggleTitle: String {
    let on = reachabilitySimulator.isReachable == false
    return on ? "Simulate offline: ON (preflight fails)" : "Simulate offline: OFF"
  }

  private var mockToggleTitle: String {
    mockModeEnabled ? "Mock mode: ON" : "Mock mode: OFF"
  }

  private func addToggleRow(titleKey: KeyPath<FKNetworkExampleViewController, String>, action: Selector) {
    let button = UIButton(type: .system)
    button.contentHorizontalAlignment = .leading
    button.titleLabel?.numberOfLines = 0
    button.addTarget(self, action: action, for: .touchUpInside)
    button.setTitle(self[keyPath: titleKey], for: .normal)
    button.tag = toggleTag(for: action)
    contentStack.addArrangedSubview(button)
  }

  private func toggleTag(for action: Selector) -> Int {
    switch action {
    case #selector(toggleSimulatedOffline): return 9001
    case #selector(toggleMockMode): return 9002
    default: return 0
    }
  }

  private func refreshToggleTitles() {
    for view in contentStack.arrangedSubviews where view.tag == 9001 {
      (view as? UIButton)?.setTitle(offlineToggleTitle, for: .normal)
    }
    for view in contentStack.arrangedSubviews where view.tag == 9002 {
      (view as? UIButton)?.setTitle(mockToggleTitle, for: .normal)
    }
  }

  @objc private func toggleSimulatedOffline() {
    reachabilitySimulator.isReachable.toggle()
    refreshToggleTitles()
    appendLog(reachabilitySimulator.isReachable ? "Reachability: online." : "Reachability: offline (send preflight returns .offline).")
  }

  @objc private func toggleMockMode() {
    mockModeEnabled.toggle()
    primaryConfig.enableMock = mockModeEnabled
    refreshToggleTitles()
    appendLog(mockModeEnabled ? "Mock mode enabled on JSONPlaceholder client (short-circuits transport when request.mockData is set)." : "Mock mode disabled.")
  }

  // MARK: - JSONPlaceholder demos

  private func runGETUser() {
    appendLog("[JSONPlaceholder] GET /users/1")
    cancellableTask = jsonClient.send(FKNetworkGETUserRequest(userID: 1)) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] GET result: \(self?.describe(result) ?? "")")
    }
  }

  private func runMergedQueryPosts() {
    appendLog("[JSONPlaceholder] GET /posts?_limit=5 plus commonQueryItems source=…")
    cancellableTask = jsonClient.send(FKNetworkCommonQueryPostsRequest()) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] Posts: \(self?.describe(result) ?? "")")
    }
  }

  private func runCustomHeaderPosts() {
    appendLog("[JSONPlaceholder] GET /posts?_limit=3 with X-Demo-Header")
    cancellableTask = jsonClient.send(FKNetworkCustomHeaderPostsRequest()) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] Posts: \(self?.describe(result) ?? "")")
    }
  }

  private func runPOSTJSON() {
    appendLog("[JSONPlaceholder] POST /posts (application/json)")
    cancellableTask = jsonClient.send(
      FKNetworkPOSTJSONPostRequest(
        title: "FKNetwork example post",
        body: "Demonstrates JSONEncoding.",
        userID: 1
      )
    ) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] POST: \(self?.describe(result) ?? "")")
    }
  }

  private func runPUTPost() {
    appendLog("[JSONPlaceholder] PUT /posts/1 (full resource)")
    cancellableTask = jsonClient.send(FKNetworkPUTPostRequest()) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] PUT: \(self?.describe(result) ?? "")")
    }
  }

  private func runPATCHPost() {
    appendLog("[JSONPlaceholder] PATCH /posts/1 (partial)")
    cancellableTask = jsonClient.send(FKNetworkPATCHPostRequest()) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] PATCH: \(self?.describe(result) ?? "")")
    }
  }

  private func runDELETEPost() {
    appendLog("[JSONPlaceholder] DELETE /posts/1 — repeat calls may return 404 from the sandbox API.")
    cancellableTask = jsonClient.send(FKNetworkDELETEPostRequest()) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] DELETE: \(self?.describe(result) ?? "")")
    }
  }

  private func runMemoryCacheUser() {
    appendLog("[JSONPlaceholder] Cache policy .memory(ttl: 60) — run twice to observe cache hit logs.")
    cancellableTask = jsonClient.send(FKNetworkMemoryCachedUserRequest(userID: 1)) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] Memory cache GET: \(self?.describe(result) ?? "")")
    }
  }

  private func runDiskCacheUser() {
    appendLog("[JSONPlaceholder] Cache policy .disk(ttl: 60)")
    cancellableTask = jsonClient.send(FKNetworkDiskCachedUserRequest(userID: 1)) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] Disk cache GET: \(self?.describe(result) ?? "")")
    }
  }

  private func runMemoryDiskCacheUser() {
    appendLog("[JSONPlaceholder] Cache policy .memoryAndDisk(ttl: 120)")
    cancellableTask = jsonClient.send(FKNetworkMemoryAndDiskCachedUserRequest(userID: 1)) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] Memory+disk GET: \(self?.describe(result) ?? "")")
    }
  }

  private func runDedupPair() {
    appendLog("[HTTPBin] Two identical .idempotentDeduplicated GET /delay/1 — expect B: businessError deduplicated; A: success after ~1s.")
    httpBinClient.send(FKNetworkHttpBinDedupDelayRequest()) { [weak self] result in
      self?.appendLog("[HTTPBin] Dedup request A: \(self?.describe(result) ?? "")")
    }
    httpBinClient.send(FKNetworkHttpBinDedupDelayRequest()) { [weak self] result in
      self?.appendLog("[HTTPBin] Dedup request B: \(self?.describe(result) ?? "")")
    }
  }

  /// Optional: JSONPlaceholder dedup when latency is high enough (same cache key as normal GET posts).
  private func runDedupJSONPlaceholderPair() {
    appendLog("[JSONPlaceholder] Dedup experiment — may succeed twice if the sandbox responds faster than the second send.")
    jsonClient.send(FKNetworkDedupPostsRequest()) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] Dedup A: \(self?.describe(result) ?? "")")
    }
    jsonClient.send(FKNetworkDedupPostsRequest()) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] Dedup B: \(self?.describe(result) ?? "")")
    }
  }

  private func runEnvelopeMockUser() {
    guard mockModeEnabled else {
      appendLog("Turn Mock mode ON first (envelope mock uses request.mockData).")
      return
    }
    appendLog("[JSONPlaceholder] Mock user — envelope wrapped; interceptor unwraps `data`.")
    cancellableTask = jsonClient.send(FKNetworkEnvelopeMockUserRequest()) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] Envelope mock: \(self?.describe(result) ?? "")")
    }
  }

  private func runPlainMockUser() {
    guard mockModeEnabled else {
      appendLog("Turn Mock mode ON first.")
      return
    }
    appendLog("[JSONPlaceholder] Mock user — plain JSON; interceptor no-op.")
    cancellableTask = jsonClient.send(FKNetworkPlainMockUserRequest()) { [weak self] result in
      self?.appendLog("[JSONPlaceholder] Plain mock: \(self?.describe(result) ?? "")")
    }
  }

  private func runAsyncAwaitUser() {
    appendLog("[JSONPlaceholder] async/await GET /users/2")
    Task { [weak self] in
      guard let self else { return }
      do {
        let user = try await jsonClient.send(FKNetworkGETUserRequest(userID: 2))
        appendLog("[JSONPlaceholder] async/await success: \(user.name)")
      } catch {
        appendLog("[JSONPlaceholder] async/await error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - HTTPBin demos

  private func runBearer401Flow() {
    tokenStore.accessToken = nil
    tokenStore.refreshToken = "demo-refresh-token"
    appendLog("[HTTPBin] GET /bearer without Authorization → 401 → FKNetworkClient refresh → retry with Bearer.")
    cancellableTask = httpBinClient.send(FKNetworkHttpBinBearerRequest()) { [weak self] result in
      switch result {
      case let .success(payload):
        self?.appendLog("[HTTPBin] Bearer OK authenticated=\(payload.authenticated) token=\(payload.token ?? "nil")")
      case let .failure(error):
        self?.appendLog("[HTTPBin] Bearer flow failed: \(error.localizedDescription)")
      }
    }
  }

  private func runSignedGET() {
    appendLog("[HTTPBin] GET /get — inspect echoed headers for X-FK-Example-Trace, X-Timestamp, X-Signature.")
    cancellableTask = httpBinClient.send(FKNetworkHttpBinSignedGETRequest()) { [weak self] result in
      switch result {
      case let .success(payload):
        let keys = payload.headers.keys.sorted().joined(separator: ", ")
        self?.appendLog("[HTTPBin] /get header keys (sample): \(keys)")
        let trace = payload.headers.first { $0.key.lowercased() == "x-fk-example-trace" }
        let sig = payload.headers.first { $0.key.lowercased() == "x-signature" }
        self?.appendLog("[HTTPBin] Trace=\(trace?.value ?? "n/a") Signature=\(sig?.value.prefix(16) ?? "n/a")…")
      case let .failure(error):
        self?.appendLog("[HTTPBin] /get failed: \(error.localizedDescription)")
      }
    }
  }

  private func runFormURLEncodedPOST() {
    appendLog("[HTTPBin] POST /post form-urlencoded body")
    cancellableTask = httpBinClient.send(FKNetworkHttpBinFormPOSTRequest()) { [weak self] result in
      switch result {
      case let .success(payload):
        let formDesc = payload.form?.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: "&") ?? "nil"
        self?.appendLog("[HTTPBin] Echoed form: \(formDesc)")
      case let .failure(error):
        self?.appendLog("[HTTPBin] Form POST failed: \(error.localizedDescription)")
      }
    }
  }

  private func runDelayedGETForCancel() {
    appendLog("[HTTPBin] GET /delay/2 — use Cancel to stop early (may yield resume data only on download tasks).")
    cancellableTask = httpBinClient.send(FKNetworkHttpBinDelayGETRequest()) { [weak self] result in
      self?.appendLog("[HTTPBin] Delay GET finished: \(self?.describe(result) ?? "")")
    }
  }

  // MARK: - Upload / download

  private func runUpload() {
    appendLog("[Networkable.upload] POST multipart stream from file URL → httpbin.org/post")
    let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("fk-network-upload-demo.txt")
    do {
      try Data("FKNetwork upload demo payload".utf8).write(to: tempFile, options: .atomic)
    } catch {
      appendLog("Failed to write temp upload file: \(error.localizedDescription)")
      return
    }

    var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
    request.httpMethod = "POST"

    uploadTask = jsonClient.upload(request, fileURL: tempFile, progress: { [weak self] progress in
      self?.appendLog(String(format: "[Upload] progress %.0f%%", progress * 100))
    }, completion: { [weak self] result in
      switch result {
      case let .success(data):
        self?.appendLog("[Upload] completed, bytes=\(data.count)")
      case let .failure(error):
        self?.appendLog("[Upload] failed: \(error.localizedDescription)")
      }
    })
  }

  private func runDownload() {
    appendLog("[Networkable.download] GET https://httpbin.org/bytes/65536")
    var request = URLRequest(url: URL(string: "https://httpbin.org/bytes/65536")!)
    request.httpMethod = "GET"
    storedResumeData = nil

    downloadTask = jsonClient.download(request, resumeData: nil, progress: { [weak self] progress in
      self?.appendLog(String(format: "[Download] progress %.0f%%", progress * 100))
    }, completion: { [weak self] result in
      self?.handleDownloadResult(result)
    })
  }

  private func resumeDownload() {
    guard let resumeData = storedResumeData else {
      appendLog("No resume data yet — start a download, cancel mid-flight, then try again.")
      return
    }
    appendLog("[Networkable.download] Resuming with stored resume data.")
    var request = URLRequest(url: URL(string: "https://httpbin.org/bytes/65536")!)
    request.httpMethod = "GET"

    downloadTask = jsonClient.download(request, resumeData: resumeData, progress: { [weak self] progress in
      self?.appendLog(String(format: "[Download resume] progress %.0f%%", progress * 100))
    }, completion: { [weak self] result in
      self?.handleDownloadResult(result)
    })
  }

  private func handleDownloadResult(_ result: Result<(fileURL: URL, resumeData: Data?), NetworkError>) {
    switch result {
    case let .success((tempURL, _)):
      let destination = FileManager.default.temporaryDirectory.appendingPathComponent("fk-network-download.bin")
      do {
        if FileManager.default.fileExists(atPath: destination.path) {
          try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
        appendLog("[Download] saved to \(destination.lastPathComponent)")
      } catch {
        appendLog("[Download] move failed: \(error.localizedDescription)")
      }
    case let .failure(error):
      if case let .underlying(underlyingError as NSError) = error,
         let data = underlyingError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
        storedResumeData = data
        appendLog("[Download] interrupted; resume data stored for “Resume download”.")
      }
      appendLog("[Download] error: \(error.localizedDescription)")
    }
  }

  private func cancelActiveTasks() {
    cancellableTask?.cancel()
    uploadTask?.cancel()
    downloadTask?.cancel()
    appendLog("Cancelled active URLSession tasks (data / upload / download).")
  }

  private func clearLogs() {
    logView.text = ""
  }

  // MARK: - Logging helpers

  private func appendLog(_ message: String) {
    let prefix = DateFormatter.fkNetworkLogFormatter.string(from: Date())
    let line = "[\(prefix)] \(message)\n"
    logView.text.append(line)
    let end = NSRange(location: max(logView.text.count - 1, 0), length: 1)
    logView.scrollRangeToVisible(end)
  }

  private func describe<T>(_ result: Result<T, NetworkError>) -> String {
    switch result {
    case let .success(value):
      return "success — \(value)"
    case let .failure(error):
      return "failure — \(networkErrorLabel(error))"
    }
  }

  private func networkErrorLabel(_ error: NetworkError) -> String {
    switch error {
    case .invalidURL:
      return "invalidURL"
    case .invalidResponse:
      return "invalidResponse"
    case .requestCancelled:
      return "requestCancelled"
    case .noData:
      return "noData"
    case let .decodingFailed(underlying):
      return "decodingFailed(\(underlying.localizedDescription))"
    case let .serverError(code, message):
      return "serverError(\(code), \(message ?? "nil"))"
    case let .businessError(code, message):
      return "businessError(\(code), \(message))"
    case .sslValidationFailed:
      return "sslValidationFailed"
    case .offline:
      return "offline"
    case .tokenRefreshFailed:
      return "tokenRefreshFailed"
    case .signingFailed:
      return "signingFailed"
    case .encryptionFailed:
      return "encryptionFailed"
    case let .underlying(underlying):
      return "underlying(\(underlying.localizedDescription))"
    }
  }
}

private extension DateFormatter {
  static let fkNetworkLogFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
  }()
}
