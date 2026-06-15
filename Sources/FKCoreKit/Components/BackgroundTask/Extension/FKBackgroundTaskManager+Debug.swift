#if os(iOS)
import Foundation

extension FKBackgroundTaskManager {
  /// Returns summaries of pending `BGTaskScheduler` requests.
  ///
  /// Always available in DEBUG builds. In Release, returns an empty array unless
  /// ``FKBackgroundTaskManagerConfiguration/debugLogPendingTasks`` is enabled.
  public func pendingTaskRequests() async -> [FKBackgroundTaskPendingSummary] {
    #if DEBUG
    return await fetchPendingTaskRequestSummaries()
    #else
    guard configuration.debugLogPendingTasks else { return [] }
    return await fetchPendingTaskRequestSummaries()
    #endif
  }
}

#endif
