import UIKit

/// Auto Layout helpers that pin views to `UIKeyboardLayoutGuide` (iOS 15+).
@MainActor
public enum FKKeyboardLayout {
  /// Pins `view.bottomAnchor` to `host.keyboardLayoutGuide.topAnchor`.
  ///
  /// - Parameters:
  ///   - view: View whose bottom edge tracks the keyboard.
  ///   - host: Ancestor that owns the keyboard layout guide (usually the view controller’s view).
  ///   - constant: Offset applied to the constraint (negative lifts the view above the guide).
  /// - Returns: The activated bottom constraint.
  @discardableResult
  public static func pinBottom(
    of view: UIView,
    toKeyboardTopOf host: UIView,
    constant: CGFloat = 0
  ) -> NSLayoutConstraint {
    view.translatesAutoresizingMaskIntoConstraints = false
    let constraint = view.bottomAnchor.constraint(
      equalTo: host.keyboardLayoutGuide.topAnchor,
      constant: constant
    )
    constraint.isActive = true
    return constraint
  }

  /// Pins a scroll view’s bottom edge to the keyboard layout guide of `host`.
  @discardableResult
  public static func pinScrollViewBottom(
    _ scrollView: UIScrollView,
    toKeyboardTopOf host: UIView,
    constant: CGFloat = 0
  ) -> NSLayoutConstraint {
    pinBottom(of: scrollView, toKeyboardTopOf: host, constant: constant)
  }
}
