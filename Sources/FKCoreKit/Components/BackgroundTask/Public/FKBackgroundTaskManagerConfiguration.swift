import Foundation

/// Runtime configuration for ``FKBackgroundTaskManager``.
public struct FKBackgroundTaskManagerConfiguration: Sendable {
  /// When `false`, a second call to ``FKBackgroundTaskManager/installRegistrations(_:)`` throws ``FKBackgroundTaskError/alreadyInstalled``.
  public var allowsMultipleInstall: Bool

  /// Logs schedule, complete, and cancel events at debug level via ``FKLogger``.
  public var logScheduling: Bool

  /// When `true`, ``FKBackgroundTaskManager/pendingTaskRequests()`` is available in Release builds.
  public var debugLogPendingTasks: Bool

  /// Default configuration for production use.
  public static let `default` = FKBackgroundTaskManagerConfiguration(
    allowsMultipleInstall: false,
    logScheduling: false,
    debugLogPendingTasks: false
  )

  /// Creates a configuration.
  public init(
    allowsMultipleInstall: Bool = false,
    logScheduling: Bool = false,
    debugLogPendingTasks: Bool = false
  ) {
    self.allowsMultipleInstall = allowsMultipleInstall
    self.logScheduling = logScheduling
    self.debugLogPendingTasks = debugLogPendingTasks
  }
}
