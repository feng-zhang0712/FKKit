#if os(iOS)
import Foundation
import UIKit

/// In-memory ``FKBackgroundTaskScheduling`` and ``FKBackgroundWorkExtending`` implementation for tests and FKKitExamples.
public final class FKMockBackgroundTaskScheduler: FKBackgroundTaskScheduling, FKBackgroundWorkExtending, @unchecked Sendable {
  struct RegistryEntry {
    let kind: FKBackgroundTaskRegistration.Kind
    let handler: FKBackgroundTaskHandler
  }

  private let stateQueue = DispatchQueue(label: "com.fkkit.background-task.mock")
  private let workSession: FKBackgroundWorkSession
  private var registry: [String: RegistryEntry] = [:]
  private var _scheduledRefresh: [FKBackgroundAppRefreshRequest] = []
  private var _scheduledProcessing: [FKBackgroundProcessingRequest] = []
  private var _isInstalled = false

  /// Submitted app refresh requests in schedule order.
  public var scheduledRefresh: [FKBackgroundAppRefreshRequest] {
    stateQueue.sync { _scheduledRefresh }
  }

  /// Submitted processing requests in schedule order.
  public var scheduledProcessing: [FKBackgroundProcessingRequest] {
    stateQueue.sync { _scheduledProcessing }
  }

  /// Optional override invoked by ``simulateLaunch(identifier:)`` instead of the registered handler when set.
  public var simulateHandler: (@Sendable (String) async -> Bool)? {
    get { stateQueue.sync { _simulateHandler } }
    set { stateQueue.sync { _simulateHandler = newValue } }
  }

  private var _simulateHandler: (@Sendable (String) async -> Bool)?

  /// Creates an empty mock scheduler.
  public init(application: MockBackgroundApplication = MockBackgroundApplication()) {
    self.workSession = FKBackgroundWorkSession(application: application)
  }

  /// Marks installation complete for schedule/cancel validation (mirrors ``FKBackgroundTaskManager/installRegistrations(_:)``).
  public func markInstalled() {
    stateQueue.sync { _isInstalled = true }
  }

  /// Validates registrations and marks installation complete, matching production bootstrap behavior.
  public func installRegistrations(_ registrations: [FKBackgroundTaskRegistration]) throws {
    try stateQueue.sync {
      for registration in registrations {
        guard let entry = registry[registration.identifier] else {
          throw FKBackgroundTaskError.unregisteredIdentifier(registration.identifier)
        }
        guard entry.kind == registration.kind else {
          throw FKBackgroundTaskError.duplicateRegistration(registration.identifier)
        }
      }
      _isInstalled = true
    }
  }

  /// Registers an app refresh handler in memory.
  public func registerAppRefresh(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws {
    try register(identifier: identifier, kind: .appRefresh, handler: handler)
  }

  /// Registers a processing handler in memory.
  public func registerProcessing(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws {
    try register(identifier: identifier, kind: .processing, handler: handler)
  }

  /// Records an app refresh schedule request.
  public func scheduleAppRefresh(_ request: FKBackgroundAppRefreshRequest) async throws {
    try ensureCanSchedule(identifier: request.identifier, expectedKind: .appRefresh)
    stateQueue.sync { _scheduledRefresh.append(request) }
  }

  /// Records a processing schedule request.
  public func scheduleProcessing(_ request: FKBackgroundProcessingRequest) async throws {
    try ensureCanSchedule(identifier: request.identifier, expectedKind: .processing)
    stateQueue.sync { _scheduledProcessing.append(request) }
  }

  /// Removes pending schedule records for the identifier.
  public func cancelScheduledTask(withIdentifier identifier: String) async throws {
    try stateQueue.sync {
      guard _isInstalled else { throw FKBackgroundTaskError.notInstalled }
      guard registry[identifier] != nil else {
        throw FKBackgroundTaskError.unregisteredIdentifier(identifier)
      }
      _scheduledRefresh.removeAll { $0.identifier == identifier }
      _scheduledProcessing.removeAll { $0.identifier == identifier }
    }
  }

  /// Manually invokes a registered handler as if the system launched the task.
  ///
  /// Set `simulateExpiration` to `true` to exercise cooperative cancellation and `isExpired` checks.
  public func simulateLaunch(identifier: String, simulateExpiration: Bool = false) async {
    let snapshot: (FKBackgroundTaskHandler?, (@Sendable (String) async -> Bool)?) = stateQueue.sync {
      (registry[identifier]?.handler, _simulateHandler)
    }

    let completer = MockBGTaskCompleter()
    let handle = FKBackgroundTaskHandle(task: completer, identifier: identifier)

    if simulateExpiration {
      handle.markExpired()
    }

    var success = false
    defer { handle.complete(success: success) }

    if let simulateHandler = snapshot.1 {
      success = await simulateHandler(identifier) && !handle.isExpired
      return
    }

    guard let handler = snapshot.0 else { return }

    let result = await handler(handle)
    success = result && !handle.isExpired
  }

  /// Starts async work immediately using an in-memory background application wrapper.
  @discardableResult
  public func beginBackgroundWork(
    name: String?,
    work: @escaping @Sendable () async -> Void
  ) -> FKBackgroundWorkToken {
    workSession.beginBackgroundWork(name: name, work: work)
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
  }

  private func ensureCanSchedule(
    identifier: String,
    expectedKind: FKBackgroundTaskRegistration.Kind
  ) throws {
    try stateQueue.sync {
      guard _isInstalled else { throw FKBackgroundTaskError.notInstalled }
      guard let entry = registry[identifier] else {
        throw FKBackgroundTaskError.unregisteredIdentifier(identifier)
      }
      guard entry.kind == expectedKind else {
        throw FKBackgroundTaskError.unregisteredIdentifier(identifier)
      }
    }
  }
}

/// In-memory `UIApplication` background task wrapper for mock schedulers.
public final class MockBackgroundApplication: FKBackgroundApplicationType, @unchecked Sendable {
  private let lock = NSLock()
  private var nextIdentifier = 1
  private var activeIdentifiers: Set<UIBackgroundTaskIdentifier> = []
  private var expirationHandlers: [UIBackgroundTaskIdentifier: @Sendable () -> Void] = [:]

  /// Active background task identifiers.
  public var activeTaskCount: Int {
    lock.withLock { activeIdentifiers.count }
  }

  /// Creates an empty mock application.
  public init() {}

  /// Simulates system expiration for a running background task.
  public func simulateExpiration(for identifier: UIBackgroundTaskIdentifier) {
    let handler: (@Sendable () -> Void)? = lock.withLock {
      expirationHandlers[identifier]
    }
    handler?()
  }

  /// Simulates expiration on the lowest active background task identifier, if any.
  @discardableResult
  public func simulateExpirationForFirstActiveTask() -> UIBackgroundTaskIdentifier? {
    let identifier: UIBackgroundTaskIdentifier? = lock.withLock {
      activeIdentifiers.min { $0.rawValue < $1.rawValue }
    }
    guard let identifier else { return nil }
    simulateExpiration(for: identifier)
    return identifier
  }

  func beginBackgroundTask(withName name: String?, expirationHandler: (@Sendable () -> Void)?) -> UIBackgroundTaskIdentifier {
    lock.withLock {
      let identifier = UIBackgroundTaskIdentifier(rawValue: nextIdentifier)
      nextIdentifier += 1
      activeIdentifiers.insert(identifier)
      if let expirationHandler {
        expirationHandlers[identifier] = expirationHandler
      }
      return identifier
    }
  }

  func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
    lock.withLock {
      activeIdentifiers.remove(identifier)
      expirationHandlers[identifier] = nil
    }
  }
}

#endif
