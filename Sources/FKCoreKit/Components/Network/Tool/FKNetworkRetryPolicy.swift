import Foundation

/// Backoff strategy used by HTTP retry policies.
public enum FKRetryBackoff: Sendable, Equatable {
  /// Fixed delay between attempts.
  case constant(TimeInterval)
  /// Exponential delay with optional jitter ratio in `[0, 1]`.
  case exponential(base: TimeInterval, multiplier: Double, jitter: Double)
}

/// Categories of transport failures eligible for HTTP retry.
public enum FKRetryableNetworkErrorCategory: Sendable, Hashable {
  case timedOut
  case connectionLost
  case notConnectedToInternet
  case httpStatus(Int)
}

/// Configurable HTTP retry policy applied after token-refresh handling.
public struct FKNetworkRetryPolicy: Sendable, Equatable {
  /// Maximum number of HTTP retries after the initial attempt.
  public var maxRetryCount: Int
  /// Delay strategy between attempts.
  public var backoff: FKRetryBackoff
  /// Retryable non-2xx status codes.
  public var retryableHTTPStatusCodes: Set<Int>
  /// Retryable transport error categories.
  public var retryableNetworkErrors: Set<FKRetryableNetworkErrorCategory>
  /// When `true`, only GET/HEAD or `Requestable.isIdempotent` requests are retried.
  public var idempotentMethodsOnly: Bool

  /// Creates a retry policy.
  public init(
    maxRetryCount: Int = 0,
    backoff: FKRetryBackoff = .constant(0),
    retryableHTTPStatusCodes: Set<Int> = [],
    retryableNetworkErrors: Set<FKRetryableNetworkErrorCategory> = [],
    idempotentMethodsOnly: Bool = true
  ) {
    self.maxRetryCount = min(max(maxRetryCount, 0), 5)
    self.backoff = backoff
    self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
    self.retryableNetworkErrors = retryableNetworkErrors
    self.idempotentMethodsOnly = idempotentMethodsOnly
  }

  /// Disables HTTP retry.
  public static let none = FKNetworkRetryPolicy()

  /// Retries GET/HEAD up to three times with exponential backoff for 502/503/504 and transient transport errors.
  public static let conservativeGET = FKNetworkRetryPolicy(
    maxRetryCount: 3,
    backoff: .exponential(base: 0.5, multiplier: 2, jitter: 0.1),
    retryableHTTPStatusCodes: [502, 503, 504],
    retryableNetworkErrors: [.timedOut, .connectionLost, .notConnectedToInternet],
    idempotentMethodsOnly: true
  )

  /// Retries idempotent requests (including `Requestable.isIdempotent`) up to five times.
  public static let aggressiveIdempotent = FKNetworkRetryPolicy(
    maxRetryCount: 5,
    backoff: .exponential(base: 0.25, multiplier: 2, jitter: 0.15),
    retryableHTTPStatusCodes: [502, 503, 504],
    retryableNetworkErrors: [.timedOut, .connectionLost, .notConnectedToInternet],
    idempotentMethodsOnly: true
  )
}
