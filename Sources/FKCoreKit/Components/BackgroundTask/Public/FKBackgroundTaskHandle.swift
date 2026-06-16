#if os(iOS)
import Foundation
@preconcurrency import BackgroundTasks

protocol FKBGTaskCompleting: AnyObject {
  func setTaskCompleted(success: Bool)
}

extension BGTask: FKBGTaskCompleting {}

/// In-memory task completion tracker for ``FKMockBackgroundTaskScheduler/simulateLaunch(identifier:)``.
final class MockBGTaskCompleter: FKBGTaskCompleting, @unchecked Sendable {
  private let lock = NSLock()
  private(set) var completedWithSuccess: Bool?

  func setTaskCompleted(success: Bool) {
    lock.withLock { completedWithSuccess = success }
  }
}

/// Shared handle for one background task execution. Reference type — do not treat as a value type.
public final class FKBackgroundTaskHandle: @unchecked Sendable {
  /// Registered task identifier for this execution.
  public let identifier: String

  /// Whether the system expiration handler has fired.
  public var isExpired: Bool {
    lock.withLock { _isExpired }
  }

  private let task: FKBGTaskCompleting
  private let lock = NSLock()
  private var _isExpired = false
  private var _completed = false
  private var workTask: Task<Void, Never>?

  init(task: FKBGTaskCompleting, identifier: String) {
    self.task = task
    self.identifier = identifier
  }

  /// Associates the cooperative `Task` running the handler for cancellation on expiration.
  func setWorkTask(_ task: Task<Void, Never>?) {
    lock.withLock { workTask = task }
  }

  /// Marks the handle as expired, cancels cooperative work, and completes with failure when not already completed.
  func markExpired() {
    let taskToCancel: Task<Void, Never>? = lock.withLock {
      _isExpired = true
      return workTask
    }
    taskToCancel?.cancel()
    complete(success: false)
  }

  /// Marks the task complete. Safe to call once; subsequent calls are ignored.
  public func complete(success: Bool) {
    let shouldComplete: Bool = lock.withLock {
      guard !_completed else { return false }
      _completed = true
      return true
    }
    guard shouldComplete else { return }
    task.setTaskCompleted(success: success)
  }
}

#endif
