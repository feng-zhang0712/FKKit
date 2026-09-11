import Foundation
import UIKit

/// Observes system keyboard frame notifications and publishes ``FKKeyboardInfo`` snapshots.
///
/// Observation is **opt-in**: call ``start()`` to begin and ``stop()`` (or release the instance) to tear down.
/// Nothing is registered at init time.
@MainActor
public final class FKKeyboardObserver {
  /// Latest keyboard snapshot. Starts as ``FKKeyboardInfo/hidden``.
  public private(set) var current: FKKeyboardInfo = .hidden

  /// Invoked on the main actor whenever the keyboard frame changes (including hide).
  public var onChange: ((FKKeyboardInfo) -> Void)?

  /// When `true`, ``stop()`` emits a hidden snapshot through ``onChange``.
  public var postsHiddenInfoOnStop: Bool = true

  private let tokenStorage = TokenStorage()

  /// Creates an inactive observer.
  public init() {}

  deinit {
    let center = NotificationCenter.default
    tokenStorage.tokens.forEach { center.removeObserver($0) }
    tokenStorage.tokens.removeAll()
  }

  /// Begins observing keyboard notifications. Idempotent while already running.
  public func start() {
    guard tokenStorage.tokens.isEmpty else { return }

    let center = NotificationCenter.default
    // Delivered on `queue: .main` — publish synchronously so `FKKeyboard.animate(alongside:)`
    // still runs inside the system keyboard animation transaction (a `Task` hop is one turn late).
    let handler: @Sendable (Notification) -> Void = { [weak self] notification in
      // Parse off the MainActor isolation boundary (Sendable snapshot), then publish
      // synchronously on the main queue so keyboard-curve animations stay in sync.
      let info = FKKeyboardNotificationParsing.info(from: notification)
      MainActor.assumeIsolated {
        self?.publish(info)
      }
    }

    tokenStorage.tokens.append(
      center.addObserver(
        forName: UIResponder.keyboardWillChangeFrameNotification,
        object: nil,
        queue: .main,
        using: handler
      )
    )
    tokenStorage.tokens.append(
      center.addObserver(
        forName: UIResponder.keyboardWillHideNotification,
        object: nil,
        queue: .main,
        using: handler
      )
    )
  }

  /// Removes notification observers. Optionally publishes ``FKKeyboardInfo/hidden``.
  public func stop() {
    guard !tokenStorage.tokens.isEmpty else { return }
    let center = NotificationCenter.default
    tokenStorage.tokens.forEach { center.removeObserver($0) }
    tokenStorage.tokens.removeAll()
    if postsHiddenInfoOnStop {
      publish(.hidden)
    } else {
      current = .hidden
    }
  }

  private func publish(_ info: FKKeyboardInfo) {
    current = info
    onChange?(info)
  }
}

private final class TokenStorage: @unchecked Sendable {
  var tokens: [NSObjectProtocol] = []
}
