#if os(iOS)
import Foundation
import UIKit

/// Abstraction over `UIApplication` background task APIs for testing.
protocol FKBackgroundApplicationType: Sendable {
  func beginBackgroundTask(withName name: String?, expirationHandler: (@Sendable () -> Void)?) -> UIBackgroundTaskIdentifier
  func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

/// Production `UIApplication.shared` wrapper.
final class SystemBackgroundApplication: FKBackgroundApplicationType, @unchecked Sendable {
  func beginBackgroundTask(withName name: String?, expirationHandler: (@Sendable () -> Void)?) -> UIBackgroundTaskIdentifier {
    UIApplication.shared.beginBackgroundTask(withName: name, expirationHandler: expirationHandler)
  }

  func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
    UIApplication.shared.endBackgroundTask(identifier)
  }
}

/// Manages `beginBackgroundTask` lifecycle and token validity.
final class FKBackgroundWorkSession: @unchecked Sendable {
  private let application: FKBackgroundApplicationType
  private let lock = NSLock()
  private var activeIdentifiers: Set<UIBackgroundTaskIdentifier> = []

  init(application: FKBackgroundApplicationType = SystemBackgroundApplication()) {
    self.application = application
  }

  /// Starts background work and returns a token synchronously.
  func beginBackgroundWork(
    name: String?,
    work: @escaping @Sendable () async -> Void
  ) -> FKBackgroundWorkToken {
    let taskName = name ?? "FKBackgroundWork"
    let identifierBox = BackgroundTaskIdentifierBox()
    let workTaskBox = BackgroundWorkTaskBox()

    identifierBox.identifier = application.beginBackgroundTask(withName: taskName) { [weak self] in
      workTaskBox.task?.cancel()
      self?.endBackgroundTask(identifierBox.identifier)
    }

    guard identifierBox.identifier != .invalid else {
      return FKBackgroundWorkToken(session: self, identifier: .invalid)
    }

    lock.withLock { activeIdentifiers.insert(identifierBox.identifier) }

    let token = FKBackgroundWorkToken(session: self, identifier: identifierBox.identifier)
    workTaskBox.task = Task {
      defer { token.end() }
      await work()
    }

    return token
  }

  func isBackgroundTaskValid(_ identifier: UIBackgroundTaskIdentifier) -> Bool {
    guard identifier != .invalid else { return false }
    return lock.withLock { activeIdentifiers.contains(identifier) }
  }

  func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
    guard identifier != .invalid else { return }

    let shouldEnd: Bool = lock.withLock {
      guard activeIdentifiers.remove(identifier) != nil else { return false }
      return true
    }
    guard shouldEnd else { return }
    application.endBackgroundTask(identifier)
  }
}

private final class BackgroundTaskIdentifierBox: @unchecked Sendable {
  var identifier: UIBackgroundTaskIdentifier = .invalid
}

private final class BackgroundWorkTaskBox: @unchecked Sendable {
  var task: Task<Void, Never>?
}

#endif
