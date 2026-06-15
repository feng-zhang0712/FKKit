#if os(iOS)
import Foundation
import UIKit

/// Token returned synchronously from ``FKBackgroundWorkExtending/beginBackgroundWork(name:work:)``.
public struct FKBackgroundWorkToken: Sendable {
  /// Whether the underlying UIKit background task identifier is still active.
  public var isValid: Bool {
    session.isBackgroundTaskValid(identifier)
  }

  private let session: FKBackgroundWorkSession
  private let identifier: UIBackgroundTaskIdentifier

  init(session: FKBackgroundWorkSession, identifier: UIBackgroundTaskIdentifier) {
    self.session = session
    self.identifier = identifier
  }

  /// Ends the background task. Idempotent.
  public func end() {
    session.endBackgroundTask(identifier)
  }
}

#endif
