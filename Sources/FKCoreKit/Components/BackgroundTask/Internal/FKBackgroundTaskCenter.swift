#if os(iOS)
import Foundation
@preconcurrency import BackgroundTasks

/// Registry, handler lifecycle glue, and scheduler orchestration.
final class FKBackgroundTaskCenter: @unchecked Sendable {
  struct RegistryEntry {
    let kind: FKBackgroundTaskRegistration.Kind
    let handler: FKBackgroundTaskHandler
  }

  private let scheduler: FKBGTaskSchedulerType
  private let launchQueue: DispatchQueue
  private let stateQueue = DispatchQueue(label: "com.fkkit.background-task.center")
  private let onTaskCompleted: (@Sendable (String, Bool) -> Void)?
  private var registry: [String: RegistryEntry] = [:]
  private var isInstalled = false

  init(
    scheduler: FKBGTaskSchedulerType = SystemBGTaskScheduler(),
    launchQueue: DispatchQueue = DispatchQueue(label: "com.fkkit.background-task.launch"),
    onTaskCompleted: (@Sendable (String, Bool) -> Void)? = nil
  ) {
    self.scheduler = scheduler
    self.launchQueue = launchQueue
    self.onTaskCompleted = onTaskCompleted
  }

  func registerAppRefresh(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws {
    try register(identifier: identifier, kind: .appRefresh, handler: handler)
  }

  func registerProcessing(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws {
    try register(identifier: identifier, kind: .processing, handler: handler)
  }

  func installRegistrations(
    _ registrations: [FKBackgroundTaskRegistration],
    allowsMultipleInstall: Bool
  ) throws {
    try stateQueue.sync {
      if isInstalled, !allowsMultipleInstall {
        throw FKBackgroundTaskError.alreadyInstalled
      }

      for registration in registrations {
        guard let entry = registry[registration.identifier] else {
          throw FKBackgroundTaskError.unregisteredIdentifier(registration.identifier)
        }
        guard entry.kind == registration.kind else {
          throw FKBackgroundTaskError.duplicateRegistration(registration.identifier)
        }
      }

      isInstalled = true
    }
  }

  func scheduleAppRefresh(_ request: FKBackgroundAppRefreshRequest) throws {
    try ensureCanSchedule(identifier: request.identifier, expectedKind: .appRefresh)
    let bgRequest = FKBackgroundTaskMapper.makeAppRefreshRequest(from: request)
    do {
      try scheduler.submit(bgRequest)
    } catch {
      throw FKBackgroundTaskErrorMapper.mapSubmitError(error, identifier: request.identifier)
    }
  }

  func scheduleProcessing(_ request: FKBackgroundProcessingRequest) throws {
    try ensureCanSchedule(identifier: request.identifier, expectedKind: .processing)
    let bgRequest = FKBackgroundTaskMapper.makeProcessingRequest(from: request)
    do {
      try scheduler.submit(bgRequest)
    } catch {
      throw FKBackgroundTaskErrorMapper.mapSubmitError(error, identifier: request.identifier)
    }
  }

  func cancelScheduledTask(withIdentifier identifier: String) throws {
    try stateQueue.sync {
      guard isInstalled else { throw FKBackgroundTaskError.notInstalled }
      guard registry[identifier] != nil else {
        throw FKBackgroundTaskError.unregisteredIdentifier(identifier)
      }
    }
    scheduler.cancel(taskRequestWithIdentifier: identifier)
  }

  func pendingTaskRequests() async -> [FKBackgroundTaskPendingSummary] {
    await withCheckedContinuation { continuation in
      scheduler.getPendingTaskRequests { requests in
        let summaries = requests.map(FKBackgroundTaskMapper.makePendingSummary(from:))
        continuation.resume(returning: summaries)
      }
    }
  }

  // MARK: - Private

  private func register(
    identifier: String,
    kind: FKBackgroundTaskRegistration.Kind,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws {
    try stateQueue.sync {
      if registry[identifier] != nil {
        throw FKBackgroundTaskError.duplicateRegistration(identifier)
      }
      registry[identifier] = RegistryEntry(kind: kind, handler: handler)
    }

    scheduler.register(forTaskWithIdentifier: identifier, using: launchQueue) { [weak self] task in
      self?.handleLaunch(task: task, identifier: identifier)
    }
  }

  private func handleLaunch(task: BGTask, identifier: String) {
    let handler: FKBackgroundTaskHandler? = stateQueue.sync { registry[identifier]?.handler }
    guard let handler else {
      task.setTaskCompleted(success: false)
      return
    }

    let handle = FKBackgroundTaskHandle(task: task, identifier: identifier)
    task.expirationHandler = { [weak handle] in
      handle?.markExpired()
    }

    let workTask = Task {
      var success = false
      defer {
        handle.complete(success: success)
        onTaskCompleted?(identifier, success)
      }

      guard !Task.isCancelled else { return }
      let result = await handler(handle)
      success = result && !handle.isExpired
    }
    handle.setWorkTask(workTask)
  }

  private func ensureCanSchedule(
    identifier: String,
    expectedKind: FKBackgroundTaskRegistration.Kind
  ) throws {
    try stateQueue.sync {
      guard isInstalled else { throw FKBackgroundTaskError.notInstalled }
      guard let entry = registry[identifier] else {
        throw FKBackgroundTaskError.unregisteredIdentifier(identifier)
      }
      guard entry.kind == expectedKind else {
        throw FKBackgroundTaskError.unregisteredIdentifier(identifier)
      }
    }
  }
}

#endif
