import Foundation
import UIKit

/// Shared begin-editing observation for text fields and text views.
enum FKKeyboardEditingObservation {
  /// Registers for `textDidBeginEditing` on `UITextField` and `UITextView`.
  static func addBeginEditingObservers(
    handler: @escaping @Sendable (UIView) -> Void
  ) -> [NSObjectProtocol] {
    let center = NotificationCenter.default
    let fieldHandler: @Sendable (Notification) -> Void = { note in
      guard let view = note.object as? UIView else { return }
      handler(view)
    }
    return [
      center.addObserver(
        forName: UITextField.textDidBeginEditingNotification,
        object: nil,
        queue: .main,
        using: fieldHandler
      ),
      center.addObserver(
        forName: UITextView.textDidBeginEditingNotification,
        object: nil,
        queue: .main,
        using: fieldHandler
      ),
    ]
  }

  static func remove(_ tokens: inout [NSObjectProtocol]) {
    let center = NotificationCenter.default
    tokens.forEach { center.removeObserver($0) }
    tokens.removeAll()
  }
}
