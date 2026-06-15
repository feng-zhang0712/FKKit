import Foundation

/// Default implementation of ``FKBusinessStartupTaskManaging``.
public final class FKBusinessStartupTaskManager: FKBusinessStartupTaskManaging, @unchecked Sendable {
  /// Lock protecting the task registry.
  private let lock = NSLock()
  /// Registered startup tasks keyed by task identifier.
  private var tasks: [String: FKStartupTask] = [:]

  /// Creates startup task manager.
  public init() {}

  /// Registers or replaces startup task.
  ///
  /// - Parameter task: Startup task descriptor.
  public func register(_ task: FKStartupTask) {
    lock.lock()
    tasks[task.id] = task
    lock.unlock()
  }

  /// Async wrapper that executes all registered startup tasks.
  public func runAll() async {
    await withCheckedContinuation { cont in
      runAll(completion: cont.resume)
    }
  }

  /// Executes all registered startup tasks with priority and delay.
  ///
  /// - Parameter completion: Completion callback after all tasks finish.
  public func runAll(completion: (@Sendable () -> Void)?) {
    lock.lock()
    let current = Array(tasks.values).sorted {
      if $0.priority != $1.priority { return $0.priority < $1.priority }
      return $0.delay < $1.delay
    }
    lock.unlock()

    Task(priority: .utility) {
      for task in current {
        if task.delay > 0 {
          try? await Task.sleep(nanoseconds: UInt64(task.delay * 1_000_000_000))
        }
        await task.work()
      }
      completion?()
    }
  }
}

