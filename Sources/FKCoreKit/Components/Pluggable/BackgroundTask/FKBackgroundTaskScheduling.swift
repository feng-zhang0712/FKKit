import Foundation

/// Pluggable contract for `BGTaskScheduler` registration and scheduling.
///
/// Types live in `BackgroundTask/Public/`; this protocol is the DI surface for feature modules.
/// Bootstrap via ``FKBackgroundTaskManager/installRegistrations(_:)`` is a manager convenience and is not part of this protocol.
public protocol FKBackgroundTaskScheduling: Sendable {
  /// Registers an app refresh handler with the system scheduler.
  func registerAppRefresh(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws

  /// Registers a processing handler with the system scheduler.
  func registerProcessing(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws

  /// Submits an app refresh task request.
  func scheduleAppRefresh(_ request: FKBackgroundAppRefreshRequest) async throws

  /// Submits a processing task request.
  func scheduleProcessing(_ request: FKBackgroundProcessingRequest) async throws

  /// Cancels a pending scheduled task by identifier.
  func cancelScheduledTask(withIdentifier identifier: String) async throws
}
