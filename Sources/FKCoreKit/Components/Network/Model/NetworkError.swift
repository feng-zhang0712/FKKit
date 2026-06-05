import Foundation

/// Unified error type for FKNetwork request lifecycle.
///
/// This enum normalizes transport, decoding, business, and security failures
/// into a single contract so callers can handle errors consistently.
public enum NetworkError: LocalizedError {
  /// URL construction failed.
  case invalidURL
  /// Response cannot be interpreted as valid HTTP response.
  case invalidResponse
  /// Request was cancelled by caller or URLSession.
  case requestCancelled
  /// Server returned empty body when data was expected.
  case noData
  /// Decoding from raw data to model failed.
  case decodingFailed(underlying: Error)
  /// Server returned non-2xx status code.
  case serverError(statusCode: Int, message: String?)
  /// Business layer returned explicit failure.
  case businessError(code: Int, message: String)
  /// SSL trust validation failed.
  case sslValidationFailed
  /// Network is not reachable.
  case offline
  /// Token refresh flow failed.
  case tokenRefreshFailed
  /// Signing process failed.
  case signingFailed
  /// Parameter encryption process failed.
  case encryptionFailed
  /// Fallback wrapper for unknown underlying errors.
  case underlying(Error)

  /// Human-readable error message for logging and UI display.
  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      return FKI18n.string("fkcore.network.error.invalid_url")
    case .invalidResponse:
      return FKI18n.string("fkcore.network.error.invalid_response")
    case .requestCancelled:
      return FKI18n.string("fkcore.network.error.request_cancelled")
    case .noData:
      return FKI18n.string("fkcore.network.error.no_data")
    case let .decodingFailed(underlying):
      return FKI18n.format("fkcore.network.error.decoding_failed", underlying.localizedDescription)
    case let .serverError(statusCode, message):
      return FKI18n.format(
        "fkcore.network.error.server_error",
        statusCode,
        message ?? FKI18n.string("fkcore.network.error.unknown_server_message")
      )
    case let .businessError(code, message):
      return FKI18n.format("fkcore.network.error.business_error", code, message)
    case .sslValidationFailed:
      return FKI18n.string("fkcore.network.error.ssl_validation_failed")
    case .offline:
      return FKI18n.string("fkcore.network.error.offline")
    case .tokenRefreshFailed:
      return FKI18n.string("fkcore.network.error.token_refresh_failed")
    case .signingFailed:
      return FKI18n.string("fkcore.network.error.signing_failed")
    case .encryptionFailed:
      return FKI18n.string("fkcore.network.error.encryption_failed")
    case let .underlying(error):
      return error.localizedDescription
    }
  }
}
