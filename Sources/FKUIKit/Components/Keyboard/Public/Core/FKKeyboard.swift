import UIKit

/// Facade for common keyboard utilities that do not require a long-lived controller.
@MainActor
public enum FKKeyboard {
  /// Animates changes using the keyboard notification’s duration and curve.
  public static func animate(
    alongside info: FKKeyboardInfo,
    animations: @escaping () -> Void,
    completion: ((Bool) -> Void)? = nil
  ) {
    let options = UIView.AnimationOptions(rawValue: UInt(info.animationCurveRawValue << 16))
    UIView.animate(
      withDuration: max(0, info.animationDuration),
      delay: 0,
      options: [options, .beginFromCurrentState],
      animations: animations,
      completion: completion
    )
  }

  /// Ends editing in `view`, dismissing the keyboard when it is the first-responder host.
  public static func endEditing(in view: UIView) {
    view.endEditing(true)
  }

  /// Ends editing on the nearest view controller’s view, if any.
  public static func endEditing(around view: UIView) {
    if let viewController = view.fk_nearestViewController {
      viewController.fk_endEditing()
    } else {
      view.endEditing(true)
    }
  }
}
