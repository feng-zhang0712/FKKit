#if os(iOS)
import Foundation

/// Default ``FKBackgroundTaskScheduling`` and ``FKBackgroundWorkExtending`` implementation.
///
/// Call ``installRegistrations(_:)`` synchronously before `application(_:didFinishLaunching:)` returns.
/// Register handlers via ``registerAppRefresh(identifier:handler:)`` / ``registerProcessing(identifier:handler:)`` first.
public final class FKBackgroundTaskManager: FKBackgroundTaskScheduling, FKBackgroundWorkExtending, @unchecked Sendable {
  /// Shared singleton using default configuration.
  public static let shared = FKBackgroundTaskManager()

  private let center: FKBackgroundTaskCenter
  private let workSession: FKBackgroundWorkSession
  let configuration: FKBackgroundTaskManagerConfiguration

  /// Creates a manager with optional configuration.
  public init(configuration: FKBackgroundTaskManagerConfiguration = .default) {
    self.configuration = configuration
    if configuration.logScheduling {
      self.center = FKBackgroundTaskCenter(onTaskCompleted: Self.makeCompletionLogger())
    } else {
      self.center = FKBackgroundTaskCenter()
    }
    self.workSession = FKBackgroundWorkSession()
  }

  private static func makeCompletionLogger() -> @Sendable (String, Bool) -> Void {
    { identifier, success in
      FKLogger.shared.debug("Background task '\(identifier)' completed success=\(success)")
    }
  }

  // MARK: - Bootstrap

  /// Validates that every registration has a matching handler and marks installation complete.
  ///
  /// Call once before `application(_:didFinishLaunching:)` returns, after registering handlers.
  public func installRegistrations(_ registrations: [FKBackgroundTaskRegistration]) throws {
    try center.installRegistrations(registrations, allowsMultipleInstall: configuration.allowsMultipleInstall)
  }

  // MARK: - FKBackgroundTaskScheduling

  /// Registers an app refresh handler with `BGTaskScheduler`.
  public func registerAppRefresh(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws {
    try center.registerAppRefresh(identifier: identifier, handler: handler)
  }

  /// Registers a processing handler with `BGTaskScheduler`.
  public func registerProcessing(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws {
    try center.registerProcessing(identifier: identifier, handler: handler)
  }

  /// Submits an app refresh task request.
  public func scheduleAppRefresh(_ request: FKBackgroundAppRefreshRequest) async throws {
    try center.scheduleAppRefresh(request)
    logScheduling("Scheduled app refresh '\(request.identifier)'")
  }

  /// Submits a processing task request.
  public func scheduleProcessing(_ request: FKBackgroundProcessingRequest) async throws {
    try center.scheduleProcessing(request)
    logScheduling("Scheduled processing '\(request.identifier)'")
  }

  /// Cancels a pending scheduled task by identifier.
  public func cancelScheduledTask(withIdentifier identifier: String) async throws {
    try center.cancelScheduledTask(withIdentifier: identifier)
    logScheduling("Cancelled scheduled task '\(identifier)'")
  }

  // MARK: - FKBackgroundWorkExtending

  /// Starts a UIKit background task and returns a token immediately (does not wait for `work`).
  @discardableResult
  public func beginBackgroundWork(
    name: String?,
    work: @escaping @Sendable () async -> Void
  ) -> FKBackgroundWorkToken {
    let token = workSession.beginBackgroundWork(name: name, work: work)
    if !token.isValid {
      FKLogger.shared.debug("beginBackgroundWork failed: background work unavailable.")
    }
    return token
  }

  func fetchPendingTaskRequestSummaries() async -> [FKBackgroundTaskPendingSummary] {
    await center.pendingTaskRequests()
  }

  private func logScheduling(_ message: String) {
    guard configuration.logScheduling else { return }
    FKLogger.shared.debug(message)
  }
}

#endif
