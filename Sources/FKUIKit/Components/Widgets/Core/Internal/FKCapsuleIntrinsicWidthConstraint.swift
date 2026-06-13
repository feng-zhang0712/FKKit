import UIKit

/// Pins capsule widgets to their measured pill width under Auto Layout.
///
/// Skips pinning when the view is an arranged subview of a ``UIStackView``. Stack views already
/// manage cross-axis sizing (vertical ``fill`` pins width; horizontal stacks pin leading/trailing
/// during accessory sizing). An additional equal-width constraint conflicts with those pins —
/// especially while ``UIView-Encapsulated-Layout-Width`` is still zero.
/// ``FKCapsuleLayoutEngine/pillFrame(metrics:in:layoutDirection:)`` keeps the painted pill at
/// natural width inside whatever frame Auto Layout assigns.
enum FKCapsuleIntrinsicWidthConstraint {
  @MainActor
  static func sync(on view: UIView, width: CGFloat, storage: inout NSLayoutConstraint?) {
    guard !view.translatesAutoresizingMaskIntoConstraints else {
      release(storage: &storage)
      return
    }
    guard width > 0, !isArrangedInStackView(view) else {
      release(storage: &storage)
      return
    }
    if let storage {
      if abs(storage.constant - width) > 0.5 {
        storage.constant = width
      }
    } else {
      let constraint = view.widthAnchor.constraint(equalToConstant: width)
      constraint.priority = .required
      constraint.isActive = true
      storage = constraint
    }
  }

  static func release(storage: inout NSLayoutConstraint?) {
    storage?.isActive = false
    storage = nil
  }

  /// ``UIStackView`` owns arranged-subview sizing; do not add a competing width constraint.
  private static func isArrangedInStackView(_ view: UIView) -> Bool {
    guard let stack = view.superview as? UIStackView else { return false }
    return stack.arrangedSubviews.contains(view)
  }
}
