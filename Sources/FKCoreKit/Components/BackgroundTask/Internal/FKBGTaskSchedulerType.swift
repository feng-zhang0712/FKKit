#if os(iOS)
import Foundation
@preconcurrency import BackgroundTasks

/// Abstraction over `BGTaskScheduler` for testing and dependency injection.
protocol FKBGTaskSchedulerType: Sendable {
  func register(
    forTaskWithIdentifier identifier: String,
    using queue: DispatchQueue?,
    launchHandler: @escaping @Sendable (BGTask) -> Void
  )

  func submit(_ taskRequest: BGTaskRequest) throws

  func cancel(taskRequestWithIdentifier identifier: String)

  func getPendingTaskRequests(completionHandler: @escaping @Sendable ([BGTaskRequest]) -> Void)
}

/// Production `BGTaskScheduler.shared` wrapper.
final class SystemBGTaskScheduler: FKBGTaskSchedulerType, @unchecked Sendable {
  private let scheduler = BGTaskScheduler.shared

  func register(
    forTaskWithIdentifier identifier: String,
    using queue: DispatchQueue?,
    launchHandler: @escaping @Sendable (BGTask) -> Void
  ) {
    scheduler.register(forTaskWithIdentifier: identifier, using: queue, launchHandler: launchHandler)
  }

  func submit(_ taskRequest: BGTaskRequest) throws {
    try scheduler.submit(taskRequest)
  }

  func cancel(taskRequestWithIdentifier identifier: String) {
    scheduler.cancel(taskRequestWithIdentifier: identifier)
  }

  func getPendingTaskRequests(completionHandler: @escaping @Sendable ([BGTaskRequest]) -> Void) {
    scheduler.getPendingTaskRequests(completionHandler: completionHandler)
  }
}

#endif
