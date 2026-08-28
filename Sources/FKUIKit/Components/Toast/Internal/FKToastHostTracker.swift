import UIKit

/// Dismisses a toast when its presenting view controller's view leaves the window hierarchy.
@MainActor
final class FKToastHostTracker {
  private var observation: NSKeyValueObservation?
  private let toastID: UUID
  private let onDismiss: (UUID) -> Void

  init?(host: UIViewController, toastID: UUID, onDismiss: @escaping (UUID) -> Void) {
    self.toastID = toastID
    self.onDismiss = onDismiss
    let view = host.viewIfLoaded ?? host.view
    guard let view else { return nil }
    observation = view.observe(\.window, options: [.new, .old]) { [weak self] _, change in
      guard let self else { return }
      if change.oldValue != nil, change.newValue == nil {
        Task { @MainActor in
          self.onDismiss(self.toastID)
        }
      }
    }
  }

  func invalidate() {
    observation?.invalidate()
    observation = nil
  }
}
