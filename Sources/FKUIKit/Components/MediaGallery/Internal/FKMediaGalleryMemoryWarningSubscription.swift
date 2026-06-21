import UIKit

/// Removes itself from ``NotificationCenter`` on deallocation.
final class FKMediaGalleryMemoryWarningSubscription: @unchecked Sendable {
  private var token: NSObjectProtocol?

  init(handler: @escaping @MainActor () -> Void) {
    token = NotificationCenter.default.addObserver(
      forName: UIApplication.didReceiveMemoryWarningNotification,
      object: nil,
      queue: .main
    ) { _ in
      Task { @MainActor in
        handler()
      }
    }
  }

  deinit {
    if let token {
      NotificationCenter.default.removeObserver(token)
    }
  }
}
