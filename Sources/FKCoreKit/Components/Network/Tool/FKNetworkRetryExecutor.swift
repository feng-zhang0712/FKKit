import Foundation

/// Evaluates retry eligibility and computes backoff delays for HTTP retry policies.
enum FKNetworkRetryExecutor {
  static func isMethodRetryable<R: Requestable>(request: R, policy: FKNetworkRetryPolicy) -> Bool {
    isHTTPMethodRetryable(method: request.method, isIdempotent: request.isIdempotent, policy: policy)
  }

  static func isHTTPMethodRetryable(
    method: HTTPMethod,
    isIdempotent: Bool,
    policy: FKNetworkRetryPolicy
  ) -> Bool {
    guard policy.idempotentMethodsOnly else { return true }
    if isIdempotent { return true }
    switch method {
    case .get, .head:
      return true
    default:
      return false
    }
  }

  static func shouldRetry(
    error: NetworkError,
    httpRetryCount: Int,
    policy: FKNetworkRetryPolicy
  ) -> Bool {
    guard httpRetryCount < policy.maxRetryCount else { return false }
    switch error {
    case .offline, .requestCancelled, .tokenRefreshFailed, .sslPinningFailed, .sslPinningNotConfigured:
      return false
    case let .serverError(statusCode, _):
      return policy.retryableHTTPStatusCodes.contains(statusCode)
        || policy.retryableNetworkErrors.contains(.httpStatus(statusCode))
    case let .underlying(underlying):
      return shouldRetryUnderlying(underlying, policy: policy)
    default:
      return false
    }
  }

  static func shouldRetryUnderlying(_ error: Error, policy: FKNetworkRetryPolicy) -> Bool {
    let nsError = error as NSError
    guard nsError.domain == NSURLErrorDomain else { return false }
    switch nsError.code {
    case NSURLErrorTimedOut:
      return policy.retryableNetworkErrors.contains(.timedOut)
    case NSURLErrorNetworkConnectionLost:
      return policy.retryableNetworkErrors.contains(.connectionLost)
    case NSURLErrorNotConnectedToInternet:
      return policy.retryableNetworkErrors.contains(.notConnectedToInternet)
    default:
      return false
    }
  }

  static func delay(forAttempt attempt: Int, policy: FKNetworkRetryPolicy) -> TimeInterval {
    switch policy.backoff {
    case let .constant(interval):
      return interval
    case let .exponential(base, multiplier, jitter):
      let exponential = base * pow(multiplier, Double(attempt))
      let jitterAmount = exponential * jitter * Double.random(in: 0...1)
      return exponential + jitterAmount
    }
  }
}
