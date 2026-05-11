import Foundation
import FKCoreKit

// MARK: - Reachability simulation

/// Toggle `isReachable` to demonstrate `NetworkError.offline` preflight from `FKNetworkClient`.
final class FKNetworkExampleReachabilitySimulator: NetworkStatusProviding, @unchecked Sendable {
  private let lock = NSLock()
  private var _isReachable = true

  var isReachable: Bool {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _isReachable
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      _isReachable = newValue
    }
  }
}

// MARK: - Token storage (401 refresh demo)

final class FKNetworkExampleTokenStore: TokenStore, @unchecked Sendable {
  private let lock = NSLock()
  private var _accessToken: String?
  private var _refreshToken: String?

  var accessToken: String? {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _accessToken
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      _accessToken = newValue
    }
  }

  var refreshToken: String? {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _refreshToken
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      _refreshToken = newValue
    }
  }
}

// MARK: - Token refresher

/// Supplies a synthetic bearer token after a short delay (HTTPBin accepts any non-empty Bearer value).
struct FKNetworkExampleDemoTokenRefresher: TokenRefresher, Sendable {
  func refreshToken(
    using currentRefreshToken: String?,
    completion: @escaping (Result<String, NetworkError>) -> Void
  ) {
    let delivery = TokenRefreshDelivery(completion)
    Task {
      try? await Task.sleep(nanoseconds: 250_000_000)
      await MainActor.run {
        delivery.finish(.success("fk-examples-access-token"))
      }
    }
  }
}

/// Boxes the protocol completion so `Task`/`Sendable` contexts do not capture a non-`Sendable` closure.
private final class TokenRefreshDelivery: @unchecked Sendable {
  private let completion: (Result<String, NetworkError>) -> Void
  init(_ completion: @escaping (Result<String, NetworkError>) -> Void) {
    self.completion = completion
  }
  func finish(_ result: Result<String, NetworkError>) {
    completion(result)
  }
}

// MARK: - Request interceptor (trace header)

/// Adds a per-request trace identifier visible in HTTPBin `/get` → `headers`.
struct FKNetworkExampleTraceInterceptor: RequestInterceptor, Sendable {
  func intercept(_ request: URLRequest) throws -> URLRequest {
    var mutable = request
    mutable.setValue(UUID().uuidString, forHTTPHeaderField: "X-FK-Example-Trace")
    return mutable
  }
}

// MARK: - Response interceptor (envelope unwrap)

/// If the JSON root is `{ "data": { ... } }`, replaces payload with the inner object for decoding.
/// JSONPlaceholder responses pass through unchanged (no top-level `data` envelope).
struct FKNetworkExampleEnvelopeInterceptor: ResponseInterceptor, Sendable {
  func intercept(data: Data, response: HTTPURLResponse) throws -> Data {
    guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let inner = obj["data"],
          JSONSerialization.isValidJSONObject(inner)
    else {
      return data
    }
    return try JSONSerialization.data(withJSONObject: inner)
  }
}
