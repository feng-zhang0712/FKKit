import Foundation

/// Bridges ``FKRequestIntercepting`` into ``RequestInterceptor``.
public struct FKRequestInterceptingAdapter: RequestInterceptor, Sendable {
  private let interceptor: any FKRequestIntercepting

  /// Creates an adapter around a pluggable request interceptor.
  public init(interceptor: any FKRequestIntercepting) {
    self.interceptor = interceptor
  }

  /// Forwards interception to the pluggable interceptor.
  public func intercept(_ request: URLRequest) throws -> URLRequest {
    try interceptor.intercept(request)
  }
}

/// Bridges ``FKResponseIntercepting`` into ``ResponseInterceptor``.
public struct FKResponseInterceptingAdapter: ResponseInterceptor, Sendable {
  private let interceptor: any FKResponseIntercepting

  /// Creates an adapter around a pluggable response interceptor.
  public init(interceptor: any FKResponseIntercepting) {
    self.interceptor = interceptor
  }

  /// Forwards interception to the pluggable response interceptor.
  public func intercept(data: Data, response: HTTPURLResponse) throws -> Data {
    try interceptor.intercept(data: data, response: response)
  }
}

/// Bridges ``FKRequestSigning`` into ``RequestSigner``.
public struct FKRequestSigningAdapter: RequestSigner, Sendable {
  private let signer: any FKRequestSigning

  /// Creates an adapter around a pluggable request signer.
  public init(signer: any FKRequestSigning) {
    self.signer = signer
  }

  /// Forwards signing to the pluggable signer.
  public func sign(_ request: URLRequest) throws -> URLRequest {
    try signer.sign(request)
  }
}

/// Adapts ``FKCredentialProviding`` to ``TokenStore``.
public final class TokenStorePluggableAdapter: TokenStore, @unchecked Sendable {
  private let credentials: FKCredentialProviding

  /// Creates a token-store adapter around credential storage.
  public init(credentials: FKCredentialProviding) {
    self.credentials = credentials
  }

  /// Current access token.
  public var accessToken: String? {
    get { credentials.accessToken }
    set { credentials.accessToken = newValue }
  }

  /// Current refresh token.
  public var refreshToken: String? {
    get { credentials.refreshToken }
    set { credentials.refreshToken = newValue }
  }
}

/// Bridges ``FKTokenRefreshing`` into ``TokenRefresher``.
public final class TokenRefresherPluggableAdapter: TokenRefresher, @unchecked Sendable {
  private let refresher: FKTokenRefreshing

  /// Creates a token-refresher adapter around a pluggable refresher.
  public init(refresher: FKTokenRefreshing) {
    self.refresher = refresher
  }

  /// Refreshes the access token using the async pluggable refresher.
  public func refreshToken(
    using currentRefreshToken: String?,
    completion: @escaping (Result<String, NetworkError>) -> Void
  ) {
    let resultBox = TokenRefreshCompletionBox(handler: completion)
    let refresher = refresher
    let refreshToken = currentRefreshToken
    Task { @MainActor in
      let result: Result<String, NetworkError>
      do {
        let token = try await refresher.refreshAccessToken(using: refreshToken)
        result = .success(token)
      } catch let error as NetworkError {
        result = .failure(error)
      } catch {
        result = .failure(.tokenRefreshFailed)
      }
      resultBox.deliver(result)
    }
  }
}

private final class TokenRefreshCompletionBox: @unchecked Sendable {
  private let handler: (Result<String, NetworkError>) -> Void

  init(handler: @escaping (Result<String, NetworkError>) -> Void) {
    self.handler = handler
  }

  func deliver(_ result: Result<String, NetworkError>) {
    handler(result)
  }
}
