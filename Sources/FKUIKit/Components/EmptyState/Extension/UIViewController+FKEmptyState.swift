import ObjectiveC.runtime
import UIKit

private enum FKEmptyStateActionObserverKeys {
  nonisolated(unsafe) static var token: UInt8 = 0
}

private final class FKEmptyStateActionHandlerBox: @unchecked Sendable {
  let handler: (FKEmptyStateAction) -> Void
  init(_ handler: @escaping (FKEmptyStateAction) -> Void) { self.handler = handler }
}

// MARK: - NotificationCenter routing

public extension UIViewController {
  /// Observes ``Notification/fkEmptyStateActionInvoked`` from `hostView.fk_emptyStateView` and forwards taps to `handler`.
  ///
  /// Removes any observer previously registered via this API on the same view controller (avoids duplicate callbacks when re-applying models).
  ///
  /// - Important: Call ``fk_clearEmptyStateActionObservers()`` when the binding is no longer needed (e.g. `viewWillDisappear`) so the notification token is released.
  func fk_bindEmptyStateActions(
    from hostView: UIView,
    handler: @escaping (FKEmptyStateAction) -> Void
  ) {
    fk_clearEmptyStateActionObservers()
    guard let source = hostView.fk_emptyStateView else { return }
    let handlerBox = FKEmptyStateActionHandlerBox(handler)
    let token = NotificationCenter.default.addObserver(
      forName: .fkEmptyStateActionInvoked,
      object: source,
      queue: .main
    ) { note in
      guard let userInfo = note.userInfo else { return }
      guard let id = userInfo[FKEmptyStateNotificationKeys.id] as? String else { return }
      let kindRaw = (userInfo[FKEmptyStateNotificationKeys.kind] as? String) ?? FKEmptyStateActionKind.primary.rawValue
      let kind = FKEmptyStateActionKind(rawValue: kindRaw) ?? .primary
      let title = (userInfo[FKEmptyStateNotificationKeys.title] as? String) ?? ""
      let payload = (userInfo[FKEmptyStateNotificationKeys.payload] as? [String: String]) ?? [:]
      let action = FKEmptyStateAction(id: id, title: title, kind: kind, payload: payload)
      MainActor.assumeIsolated {
        handlerBox.handler(action)
      }
    }
    objc_setAssociatedObject(self, &FKEmptyStateActionObserverKeys.token, token, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  /// Removes the observer installed by ``fk_bindEmptyStateActions(from:handler:)``.
  func fk_clearEmptyStateActionObservers() {
    guard let token = objc_getAssociatedObject(self, &FKEmptyStateActionObserverKeys.token) else { return }
    NotificationCenter.default.removeObserver(token)
    objc_setAssociatedObject(self, &FKEmptyStateActionObserverKeys.token, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
}
