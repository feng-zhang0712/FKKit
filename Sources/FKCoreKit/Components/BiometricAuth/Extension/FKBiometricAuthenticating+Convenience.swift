import Foundation

extension FKBiometricAuthenticating {
  /// Probes capability first; throws ``FKBiometricError`` when authentication is unavailable.
  public func authenticateIfAvailable(reason: String) async throws {
    let cap = capability()
    guard cap.canAuthenticate else {
      throw cap.probeError ?? .biometryNotAvailable
    }
    try await authenticate(reason: reason)
  }

  /// Closure-based authentication scheduled on a cooperative task.
  public func authenticate(
    reason: String,
    policy: FKBiometricPolicy,
    options: FKBiometricAuthOptions,
    completion: @escaping @Sendable (Result<Void, FKBiometricError>) -> Void
  ) {
    Task {
      do {
        try await authenticate(reason: reason, policy: policy, options: options)
        completion(.success(()))
      } catch let error as FKBiometricError {
        completion(.failure(error))
      } catch {
        completion(.failure(.underlying(code: (error as NSError).code, domain: (error as NSError).domain)))
      }
    }
  }

  /// Closure-based authentication using default policy and options.
  public func authenticate(
    reason: String,
    completion: @escaping @Sendable (Result<Void, FKBiometricError>) -> Void
  ) {
    Task {
      do {
        try await authenticate(reason: reason)
        completion(.success(()))
      } catch let error as FKBiometricError {
        completion(.failure(error))
      } catch {
        completion(.failure(.underlying(code: (error as NSError).code, domain: (error as NSError).domain)))
      }
    }
  }
}
