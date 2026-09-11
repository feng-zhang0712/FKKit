import Foundation
import UIKit
import FKCoreKit

/// Parses UIKit keyboard notification `userInfo` into ``FKKeyboardInfo``.
enum FKKeyboardNotificationParsing {
  static func info(from notification: Notification) -> FKKeyboardInfo {
    let userInfo = notification.userInfo ?? [:]
    let endFrame =
      (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
    let duration =
      (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
    let curveRaw =
      (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue
      ?? UIView.AnimationCurve.easeInOut.rawValue
    let isLocal =
      (userInfo[UIResponder.keyboardIsLocalUserInfoKey] as? Bool) ?? true

    let isHide = notification.name == UIResponder.keyboardWillHideNotification
    let hasSize = endFrame.height > 0 && endFrame.width > 0
    // Off-screen end frames still report a non-zero size; require intersection with the screen.
    // Use FKCoreKit bridge — `UIScreen.main` is MainActor-isolated under Swift 6.
    let screenBounds = CGRect(origin: .zero, size: FKMainActorUIKitBridge.screenBoundsSize())
    let intersectsScreen = endFrame.intersects(screenBounds)
    let isVisible = !isHide && isLocal && hasSize && intersectsScreen

    return FKKeyboardInfo(
      endFrameInScreen: isHide || !isLocal ? .zero : endFrame,
      animationDuration: duration,
      animationCurveRawValue: curveRaw,
      isVisible: isVisible,
      isLocal: isLocal
    )
  }
}
