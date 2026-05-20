import Foundation

/// Mutates outbound ``URLRequest`` values before dispatch.
///
/// Use for authentication headers, trace identifiers, locale metadata, or signing hooks.
public protocol FKRequestIntercepting: Sendable {
  /// Returns a modified request.
  ///
  /// - Parameter request: Original request built by the client.
  /// - Returns: Request ready for transport.
  /// - Throws: Interceptor-specific failures (missing token, invalid signature, etc.).
  func intercept(_ request: URLRequest) throws -> URLRequest
}

/// Mutates inbound response data before decoding or business handling.
///
/// Use for envelope normalization, decryption, or gzip handling.
public protocol FKResponseIntercepting: Sendable {
  /// Returns data that downstream decoders should consume.
  ///
  /// - Parameters:
  ///   - data: Raw response body.
  ///   - response: HTTP response metadata.
  /// - Returns: Processed body bytes.
  /// - Throws: Interceptor-specific failures.
  func intercept(data: Data, response: HTTPURLResponse) throws -> Data
}

/// Signs outbound requests to satisfy backend authentication policies.
public protocol FKRequestSigning: Sendable {
  /// Attaches signature metadata to the request.
  ///
  /// - Parameter request: Original request.
  /// - Returns: Signed request.
  /// - Throws: Signing failures.
  func sign(_ request: URLRequest) throws -> URLRequest
}
