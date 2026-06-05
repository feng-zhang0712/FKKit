import Foundation

/// Transport-neutral description of an HTTP API call.
///
/// Higher-level clients (Alamofire wrappers, ``FKNetworkClient``, etc.) map their
/// endpoint types into this value before invoking ``FKAPIClientProviding``.
public struct FKAPIRequest: Sendable, Hashable {
  /// Absolute or relative URL. When relative, the client resolves against its configured base URL.
  public var url: URL
  /// HTTP method.
  public var method: FKHTTPMethod
  /// Outbound headers.
  public var headers: [String: String]
  /// Raw request body. Pass `nil` for bodyless requests.
  public var body: Data?
  /// Request timeout. When `nil`, the client applies its default.
  public var timeout: TimeInterval?

  /// Creates an API request descriptor.
  ///
  /// - Parameters:
  ///   - url: Target URL.
  ///   - method: HTTP method. Defaults to `.get`.
  ///   - headers: Custom headers. Defaults to empty.
  ///   - body: Optional body data.
  ///   - timeout: Optional per-request timeout.
  public init(
    url: URL,
    method: FKHTTPMethod = .get,
    headers: [String: String] = [:],
    body: Data? = nil,
    timeout: TimeInterval? = nil
  ) {
    self.url = url
    self.method = method
    self.headers = headers
    self.body = body
    self.timeout = timeout
  }
}

/// Result of a successful transport-level API call (before business envelope parsing).
public struct FKAPIResponse: Sendable {
  /// Response payload.
  public var data: Data
  /// HTTP metadata when available.
  public var httpResponse: HTTPURLResponse?

  /// Creates a response value.
  ///
  /// - Parameters:
  ///   - data: Raw body bytes.
  ///   - httpResponse: Optional HTTP response.
  public init(data: Data, httpResponse: HTTPURLResponse?) {
    self.data = data
    self.httpResponse = httpResponse
  }
}
