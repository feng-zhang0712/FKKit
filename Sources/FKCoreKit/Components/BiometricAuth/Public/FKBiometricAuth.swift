import Foundation
@preconcurrency import LocalAuthentication

/// Default ``FKBiometricAuthenticating`` implementation backed by `LAContext`.
public final class FKBiometricAuth: FKBiometricAuthenticating, @unchecked Sendable {
  /// Shared singleton aligned with ``FKSecurity/shared``.
  public static let shared = FKBiometricAuth()

  private let configuration: FKBiometricAuthConfiguration
  private let queue = DispatchQueue(label: "com.fkkit.biometric", qos: .userInitiated)
  private var activeContext: LAContext?
  private var activeSessionID: UUID?
  private var cancelledSessionIDs: Set<UUID> = []

  /// Creates an authenticator with optional configuration.
  public init(configuration: FKBiometricAuthConfiguration = .init()) {
    self.configuration = configuration
  }

  /// Probes capability for a policy without presenting authentication UI.
  public func capability(for policy: FKBiometricPolicy) -> FKBiometricCapability {
    FKBiometricCapabilityProbe.probe(policy: policy)
  }

  /// Probes capability using ``FKBiometricAuthConfiguration/defaultPolicy``.
  public func capability() -> FKBiometricCapability {
    capability(for: configuration.defaultPolicy)
  }

  /// Authenticates with explicit policy and options.
  ///
  /// When the awaiting Swift `Task` is cancelled (for example a SwiftUI `.task` disappearing),
  /// the active `LAContext` is invalidated and this method throws ``FKBiometricError/appCancelled``.
  public func authenticate(
    reason: String,
    policy: FKBiometricPolicy,
    options: FKBiometricAuthOptions
  ) async throws {
    let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedReason.isEmpty else {
      throw FKBiometricError.invalidReason
    }

    let sessionID = UUID()
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        let resumeGuard = FKBiometricResumeGuard(continuation: continuation)
        queue.async { [self] in
          if cancelledSessionIDs.remove(sessionID) != nil {
            resumeGuard.resume(throwing: FKBiometricError.appCancelled)
            return
          }

          let resolvedPolicy = options.policy ?? policy
          let laPolicy = resolvedPolicy.laPolicy(allowPasscodeFallback: options.allowPasscodeFallback)
          let context = LAContext.fk_makeConfigured(
            configuration: configuration,
            options: options
          )
          activeContext = context
          activeSessionID = sessionID

          var probeError: NSError?
          guard context.canEvaluatePolicy(laPolicy, error: &probeError) else {
            let mapped = probeError.map { FKBiometricErrorMapper.map($0) } ?? .biometryNotAvailable
            self.finish(sessionID: sessionID, context: context, success: false)
            resumeGuard.resume(throwing: mapped)
            return
          }

          context.evaluatePolicy(laPolicy, localizedReason: trimmedReason) { [self] success, error in
            self.queue.async {
              guard self.activeSessionID == sessionID else {
                self.cancelledSessionIDs.remove(sessionID)
                resumeGuard.resume(throwing: FKBiometricError.appCancelled)
                return
              }

              if success {
                self.finish(sessionID: sessionID, context: context, success: true)
                resumeGuard.resume()
              } else {
                let mapped = error.map { FKBiometricErrorMapper.map($0) } ?? .authenticationFailed
                self.finish(sessionID: sessionID, context: context, success: false)
                resumeGuard.resume(throwing: mapped)
              }
            }
          }
        }
      }
    } onCancel: { [self] in
      cancelSession(sessionID)
    }
  }

  /// Authenticates using ``FKBiometricAuthConfiguration/defaultPolicy`` and default options.
  public func authenticate(reason: String) async throws {
    try await authenticate(
      reason: reason,
      policy: configuration.defaultPolicy,
      options: .init()
    )
  }

  /// Cancels in-flight authentication; pending calls resume with ``FKBiometricError/appCancelled``.
  public func cancelAuthentication() {
    queue.async { [self] in
      if let activeSessionID {
        cancelledSessionIDs.insert(activeSessionID)
      }
      activeContext?.invalidate()
      activeContext = nil
      activeSessionID = nil
    }
  }

  private func cancelSession(_ sessionID: UUID) {
    queue.async { [self] in
      cancelledSessionIDs.insert(sessionID)
      guard activeSessionID == sessionID else { return }
      activeContext?.invalidate()
    }
  }

  private func finish(sessionID: UUID, context: LAContext, success: Bool) {
    cancelledSessionIDs.remove(sessionID)

    let shouldInvalidate = success
      ? configuration.invalidateContextAfterSuccess
      : configuration.invalidateContextAfterFailure

    if shouldInvalidate {
      context.invalidate()
    }

    if activeSessionID == sessionID {
      activeSessionID = nil
    }

    if activeContext === context {
      activeContext = nil
    }
  }
}

/// Ensures a continuation resumes at most once across queue hops and cancellation races.
private final class FKBiometricResumeGuard: @unchecked Sendable {
  private let continuation: CheckedContinuation<Void, Error>
  private var hasResumed = false
  private let lock = NSLock()

  init(continuation: CheckedContinuation<Void, Error>) {
    self.continuation = continuation
  }

  func resume() {
    lock.lock()
    defer { lock.unlock() }
    guard hasResumed == false else { return }
    hasResumed = true
    continuation.resume()
  }

  func resume(throwing error: Error) {
    lock.lock()
    defer { lock.unlock() }
    guard hasResumed == false else { return }
    hasResumed = true
    continuation.resume(throwing: error)
  }
}
