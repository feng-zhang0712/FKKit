import Foundation
import FKCoreKit
import UIKit

// MARK: - Shared log sink

typealias FKPluggableExampleLogHandler = @Sendable (String) -> Void

// MARK: - Networking

final class DemoAPIClient: FKAPIClientProviding, @unchecked Sendable {
  var onPerform: FKPluggableExampleLogHandler?

  func perform(_ request: FKAPIRequest) async throws -> FKAPIResponse {
    let line =
      "API \(request.method.rawValue) \(request.url.absoluteString) body=\(request.body?.count ?? 0)B"
    onPerform?(line)
    let payload = Data("{\"ok\":true}".utf8)
    return FKAPIResponse(data: payload, httpResponse: nil)
  }
}

struct DemoAuthHeaderInterceptor: FKRequestIntercepting {
  let credentials: DemoCredentialStore

  func intercept(_ request: URLRequest) throws -> URLRequest {
    var copy = request
    if let token = credentials.accessToken {
      copy.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    return copy
  }
}

struct DemoJSONResponseInterceptor: FKResponseIntercepting {
  func intercept(data: Data, response: HTTPURLResponse) throws -> Data {
    data
  }
}

struct DemoTimestampRequestSigner: FKRequestSigning {
  func sign(_ request: URLRequest) throws -> URLRequest {
    var copy = request
    copy.setValue(String(Int(Date().timeIntervalSince1970)), forHTTPHeaderField: "X-Demo-Timestamp")
    return copy
  }
}

final class DemoCredentialStore: FKCredentialProviding, @unchecked Sendable {
  var accessToken: String?
  var refreshToken: String?
}

struct DemoTokenRefresher: FKTokenRefreshing {
  func refreshAccessToken(using refreshToken: String?) async throws -> String {
    guard let refreshToken, refreshToken.isEmpty == false else {
      throw URLError(.userAuthenticationRequired)
    }
    return "demo-access-\(UUID().uuidString.prefix(8))"
  }
}

struct DemoNetworkReachability: FKNetworkReachabilityProviding {
  var isReachable = true
}

// MARK: - Analytics

struct PluggableDemoAnalyticsCommonParameters: FKPluggableAnalyticsCommonParametersProviding {
  func commonParameters() -> [String: String] {
    ["app": "FKKitExamples", "contract": "\(FKPluggable.contractVersion)"]
  }
}

final class PluggableDemoAnalyticsUploader: FKPluggableAnalyticsUploading, @unchecked Sendable {
  var onUpload: FKPluggableExampleLogHandler?

  func upload(batch: [FKPluggableAnalyticsEvent]) async throws {
    let names = batch.map(\.name).joined(separator: ", ")
    onUpload?("Uploaded batch (\(batch.count)): [\(names)]")
  }
}

final class PluggableDemoAnalyticsTracker: FKPluggableAnalyticsTracking, @unchecked Sendable {
  private let lock = NSLock()
  private var uploader: (any FKPluggableAnalyticsUploading)?
  private var commonProvider: (any FKPluggableAnalyticsCommonParametersProviding)?
  private var buffer: [FKPluggableAnalyticsEvent] = []
  var onEvent: FKPluggableExampleLogHandler?

  func setUploader(_ uploader: (any FKPluggableAnalyticsUploading)?) {
    lock.lock()
    self.uploader = uploader
    lock.unlock()
  }

  func setCommonParametersProvider(_ provider: (any FKPluggableAnalyticsCommonParametersProviding)?) {
    lock.lock()
    commonProvider = provider
    lock.unlock()
  }

  func trackPageView(_ page: String, parameters: [String: String]?) {
    enqueue(name: "page_view", parameters: merged(["page": page], with: parameters))
  }

  func trackClick(element: String, page: String?, parameters: [String: String]?) {
    var params = ["element": element]
    if let page { params["page"] = page }
    enqueue(name: "click", parameters: merged(params, with: parameters))
  }

  func trackEvent(_ name: String, parameters: [String: String]?) {
    enqueue(name: name, parameters: merged([:], with: parameters))
  }

  func flush() async {
    let (batch, upload) = drainForUpload()
    guard let upload, batch.isEmpty == false else { return }
    try? await upload.upload(batch: batch)
  }

  private nonisolated func drainForUpload() -> ([FKPluggableAnalyticsEvent], (any FKPluggableAnalyticsUploading)?) {
    lock.lock()
    defer { lock.unlock() }
    let batch = buffer
    buffer = []
    let upload = uploader
    return (batch, upload)
  }

  private func enqueue(name: String, parameters: [String: String]) {
    let event = FKPluggableAnalyticsEvent(name: name, parameters: parameters)
    lock.lock()
    buffer.append(event)
    lock.unlock()
    onEvent?("Buffered: \(name) \(parameters)")
  }

  private func merged(_ base: [String: String], with extra: [String: String]?) -> [String: String] {
    var result = commonProvider?.commonParameters() ?? [:]
    result.merge(base) { _, new in new }
    if let extra { result.merge(extra) { _, new in new } }
    return result
  }
}

// MARK: - Storage

final class DemoMemoryStorage: FKCodableStoring, @unchecked Sendable {
  private var store: [String: Data] = [:]
  private let lock = NSLock()

  func data(forKey key: String) throws -> Data? {
    lock.lock()
    defer { lock.unlock() }
    return store[key]
  }

  func set(_ data: Data?, forKey key: String) throws {
    lock.lock()
    defer { lock.unlock() }
    if let data { store[key] = data } else { store.removeValue(forKey: key) }
  }

  func remove(forKey key: String) throws {
    try set(nil, forKey: key)
  }

  func contains(key: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return store[key] != nil
  }

}

// MARK: - Session

final class DemoUserSession: FKUserSessionProviding, FKUserSessionObserving, @unchecked Sendable {
  private let lock = NSLock()
  private var observers: [UUID: @Sendable (Bool) -> Void] = [:]
  private(set) var isAuthenticated = false
  private(set) var userID: String?

  func signIn(userID: String) {
    lock.lock()
    isAuthenticated = true
    self.userID = userID
    let handlers = Array(observers.values)
    lock.unlock()
    handlers.forEach { $0(true) }
  }

  func signOut() throws {
    lock.lock()
    isAuthenticated = false
    userID = nil
    let handlers = Array(observers.values)
    lock.unlock()
    handlers.forEach { $0(false) }
  }

  @discardableResult
  func observeAuthenticationChange(_ handler: @escaping @Sendable (Bool) -> Void) -> FKPluggableObservationToken {
    let id = UUID()
    lock.lock()
    observers[id] = handler
    let authenticated = isAuthenticated
    lock.unlock()
    handler(authenticated)
    return FKPluggableObservationToken { [weak self] in
      self?.lock.lock()
      self?.observers.removeValue(forKey: id)
      self?.lock.unlock()
    }
  }
}

// MARK: - Configuration

struct DemoAppEnvironment: FKAppEnvironmentProviding {
  var environment: FKAppEnvironment
  var apiBaseURL: URL
  var webBaseURL: URL?
}

struct DemoFeatureFlags: FKFeatureFlagProviding {
  var flags: [String: Bool] = ["new_checkout": true, "beta_player": false]
  var payloads: [String: String] = ["home_banner": "spring_sale"]

  func isEnabled(_ key: String) -> Bool { flags[key] ?? false }
  func stringValue(for key: String) -> String? { payloads[key] }
}

final class DemoRemoteConfig: FKRemoteConfigProviding, @unchecked Sendable {
  private var values: [String: String] = [
    "support_email": "support@example.com",
    "force_update": "false",
  ]

  func fetch() async throws {
    values["fetched_at"] = ISO8601DateFormatter().string(from: Date())
  }

  func string(forKey key: String) -> String? { values[key] }
  func bool(forKey key: String) -> Bool? {
    guard let raw = values[key] else { return nil }
    return (raw as NSString).boolValue
  }
}

// MARK: - Localization

final class DemoLocalizer: FKLocalizing, @unchecked Sendable {
  private let lock = NSLock()
  private var languageCode = "en"
  private var observers: [UUID: @Sendable (String) -> Void] = [:]
  private let table: [String: [String: String]] = [
    "en": ["greeting": "Hello", "farewell": "Goodbye"],
    "ja": ["greeting": "こんにちは", "farewell": "さようなら"],
  ]

  var currentLanguageCode: String {
    lock.lock()
    defer { lock.unlock() }
    return languageCode
  }

  func setLanguageCode(_ code: String) {
    lock.lock()
    languageCode = code
    let handlers = Array(observers.values)
    lock.unlock()
    handlers.forEach { $0(code) }
  }

  func localized(_ key: String, table tableName: String?) -> String {
    lock.lock()
    let code = languageCode
    lock.unlock()
    _ = tableName
    return table[code]?[key] ?? key
  }

  @discardableResult
  func observeLanguageChange(_ handler: @escaping @Sendable (String) -> Void) -> FKPluggableObservationToken {
    let id = UUID()
    lock.lock()
    observers[id] = handler
    let code = languageCode
    lock.unlock()
    handler(code)
    return FKPluggableObservationToken { [weak self] in
      self?.lock.lock()
      self?.observers.removeValue(forKey: id)
      self?.lock.unlock()
    }
  }
}

enum DemoTranslationKey: String, Hashable, Sendable {
  case welcomeTitle
  case itemCount
}

struct DemoTranslator: FKTranslating {
  func translate(_ key: DemoTranslationKey, locale: String, variables: [String: String]) -> String {
    switch (key, locale) {
    case (.welcomeTitle, "ja"):
      return "ようこそ"
    case (.welcomeTitle, _):
      return "Welcome"
    case (.itemCount, _):
      let count = variables["count"] ?? "0"
      return locale == "ja" ? "アイテム \(count) 件" : "\(count) items"
    }
  }
}

// MARK: - Routing

struct DemoDeeplinkParser: FKDeeplinkParsing {
  func parse(url: URL) -> FKRouteContext? {
    let parts = url.path.split(separator: "/").map(String.init)
    var query: [String: String] = [:]
    URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
      if let value = $0.value { query[$0.name] = value }
    }
    return FKRouteContext(url: url, pathComponents: parts, queryItems: query)
  }
}

struct DemoProductRouteHandler: FKRouteHandling {
  let onHandle: @MainActor (FKRouteContext) -> Void

  var routeHandlerName: String { "product" }

  func canHandle(_ context: FKRouteContext) -> Bool {
    context.pathComponents.first == "product"
  }

  @MainActor
  func handle(_ context: FKRouteContext) -> FKRouteHandlingResult {
    onHandle(context)
    return .handled
  }
}

struct DemoPromoRouteHandler: FKRouteHandling {
  let onHandle: @MainActor (FKRouteContext) -> Void

  var routeHandlerName: String { "promo" }

  func canHandle(_ context: FKRouteContext) -> Bool {
    context.pathComponents.first == "promo"
  }

  @MainActor
  func handle(_ context: FKRouteContext) -> FKRouteHandlingResult {
    onHandle(context)
    return .handled
  }
}

@MainActor
final class DemoDeeplinkRouter: FKDeeplinkRouting {
  private let parser: any FKDeeplinkParsing
  private var handlers: [any FKRouteHandling] = []

  init(parser: any FKDeeplinkParsing = DemoDeeplinkParser()) {
    self.parser = parser
  }

  func register(_ handler: any FKRouteHandling) {
    handlers.append(handler)
  }

  func open(url: URL) -> FKRouteHandlingResult {
    guard let context = parser.parse(url: url) else {
      return .failed(message: "Parser returned nil for \(url.absoluteString)")
    }
    for handler in handlers where handler.canHandle(context) {
      let result = handler.handle(context)
      if result != .notHandled { return result }
    }
    return .notHandled
  }
}

// MARK: - Logging

final class DemoPluggableLogger: FKPluggableLogging, @unchecked Sendable {
  var minimumLevel: FKPluggableLogLevel = .debug
  var onLog: FKPluggableExampleLogHandler?

  func log(level: FKPluggableLogLevel, _ message: @autoclosure () -> String, file: String, function: String, line: UInt) {
    guard level >= minimumLevel else { return }
    onLog?("[\(level)] \(message()) (\(file):\(line))")
  }
}

// MARK: - Lifecycle

final class DemoLifecycleObserver: FKAppLifecycleObserving, @unchecked Sendable {
  private let lock = NSLock()
  private(set) var state: FKPluggableAppLifecycleState = .active
  private var observers: [UUID: @Sendable (FKPluggableAppLifecycleState) -> Void] = [:]

  func simulate(_ newState: FKPluggableAppLifecycleState) {
    lock.lock()
    state = newState
    let handlers = Array(observers.values)
    lock.unlock()
    handlers.forEach { $0(newState) }
  }

  @discardableResult
  func observe(_ handler: @escaping @Sendable (FKPluggableAppLifecycleState) -> Void) -> FKPluggableObservationToken {
    let id = UUID()
    lock.lock()
    observers[id] = handler
    let current = state
    lock.unlock()
    handler(current)
    return FKPluggableObservationToken { [weak self] in
      self?.lock.lock()
      self?.observers.removeValue(forKey: id)
      self?.lock.unlock()
    }
  }
}

// MARK: - Media

@MainActor
final class DemoImageLoader: FKImageLoading {
  var cache: DemoImageCache?
  var onLoad: FKPluggableExampleLogHandler?

  func loadImage(for request: FKImageLoadRequest) async throws -> UIImage {
    onLoad?("Load image: \(request.url.lastPathComponent)")
    if let key = request.cacheKey, let cached = cache?.cachedImage(forKey: key) {
      return cached
    }
    let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
    let image = UIImage(systemName: "photo", withConfiguration: config) ?? UIImage()
    if let key = request.cacheKey {
      cache?.store(image, forKey: key)
    }
    return image
  }

  func cancelLoad(for request: FKImageLoadRequest) {
    onLoad?("Cancel load: \(request.url.lastPathComponent)")
  }
}

@MainActor
final class DemoImageCache: FKImageCaching {
  private var images: [String: UIImage] = [:]

  func cachedImage(forKey key: String) -> UIImage? { images[key] }
  func store(_ image: UIImage, forKey key: String) { images[key] = image }
  func removeImage(forKey key: String) { images.removeValue(forKey: key) }
  func removeAllImages() { images.removeAll() }
}

// MARK: - Text input

struct DemoPhoneFormatRule: Sendable {
  var maxDigits: Int = 11
}

struct DemoPhoneFormatter: FKTextFormatting {
  func format(text: String, rule: DemoPhoneFormatRule) -> FKTextFormattingResult {
    let digits = String(text.filter(\.isNumber).prefix(rule.maxDigits))
    var display = ""
    for (index, char) in digits.enumerated() {
      if index == 3 || index == 7 { display.append(" ") }
      display.append(char)
    }
    return FKTextFormattingResult(rawText: digits, displayText: display)
  }
}

struct DemoPhoneValidator: FKTextValidating {
  func validate(rawText: String, displayText: String, rule: DemoPhoneFormatRule) -> FKTextValidationResult {
    _ = displayText
    _ = rule
    if rawText.count == 11 { return .valid }
    return .invalid(message: "Phone must be 11 digits (raw=\(rawText.count))")
  }
}

struct DemoAsyncValidationRule: Sendable {}

final class DemoUsernameAsyncValidator: FKTextAsyncValidating, @unchecked Sendable {
  var reservedNames: Set<String> = ["admin", "root", "system"]

  func validate(rawText: String, displayText: String, rule: DemoAsyncValidationRule) async throws -> FKTextValidationResult {
    _ = displayText
    _ = rule
    try await Task.sleep(nanoseconds: 300_000_000)
    if reservedNames.contains(rawText.lowercased()) {
      return .invalid(message: "'\(rawText)' is reserved")
    }
    return .valid
  }
}
