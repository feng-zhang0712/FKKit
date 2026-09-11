import Foundation
import UIKit

/// Immutable snapshot of a system keyboard frame change.
public struct FKKeyboardInfo: Equatable, Sendable {
  /// Keyboard end frame in screen coordinates (`UIWindow` / screen space).
  public var endFrameInScreen: CGRect

  /// Animation duration from the keyboard notification, in seconds.
  public var animationDuration: TimeInterval

  /// Animation curve raw value from the keyboard notification.
  public var animationCurveRawValue: Int

  /// Whether this keyboard belongs to the current app (`keyboardIsLocalUserInfoKey`).
  ///
  /// Non-local keyboards (for example another app’s keyboard in Stage Manager) should not drive avoidance.
  public var isLocal: Bool

  /// Whether the keyboard overlaps the screen meaningfully for the current app.
  public var isVisible: Bool

  /// Creates a keyboard info snapshot.
  public init(
    endFrameInScreen: CGRect,
    animationDuration: TimeInterval,
    animationCurveRawValue: Int,
    isVisible: Bool,
    isLocal: Bool = true
  ) {
    self.endFrameInScreen = endFrameInScreen
    self.animationDuration = animationDuration
    self.animationCurveRawValue = animationCurveRawValue
    self.isLocal = isLocal
    self.isVisible = isVisible
  }

  /// Builds a snapshot from a UIKit keyboard notification.
  public static func from(notification: Notification) -> FKKeyboardInfo {
    FKKeyboardNotificationParsing.info(from: notification)
  }

  /// Hidden / zero-height keyboard info using a typical dismiss duration.
  public static let hidden = FKKeyboardInfo(
    endFrameInScreen: .zero,
    animationDuration: 0.25,
    animationCurveRawValue: UIView.AnimationCurve.easeInOut.rawValue,
    isVisible: false,
    isLocal: true
  )

  /// UIKit animation curve for coordinating layout animations.
  public var animationCurve: UIView.AnimationCurve {
    UIView.AnimationCurve(rawValue: animationCurveRawValue) ?? .easeInOut
  }

  /// Keyboard end frame converted into `view`’s coordinate space.
  @MainActor
  public func endFrame(in view: UIView) -> CGRect {
    guard isVisible else { return .zero }
    let endInWindow = view.window?.convert(endFrameInScreen, from: nil) ?? endFrameInScreen
    return view.convert(endInWindow, from: view.window)
  }

  /// Y origin of the keyboard’s top edge inside `view`’s bounds (or `view.bounds.maxY` when hidden).
  ///
  /// Use this for transform / layout that must clear the **visual** keyboard. Prefer
  /// ``overlapHeight(in:subtractSafeAreaBottom:additionalBottomInset:)`` when applying scroll
  /// `contentInset` so home-indicator inset is not double-counted.
  @MainActor
  public func keyboardTopY(in view: UIView) -> CGFloat {
    guard isVisible else { return view.bounds.maxY }
    let frame = endFrame(in: view)
    guard !frame.isNull, frame.height > 0 else { return view.bounds.maxY }
    return frame.minY
  }

  /// Overlap height of the keyboard within `view`’s bounds, in the view’s coordinate space.
  ///
  /// - Parameters:
  ///   - view: Reference view used for coordinate conversion and safe-area subtraction.
  ///   - subtractSafeAreaBottom: When `true` (default), home-indicator inset is not double-counted.
  ///   - additionalBottomInset: Extra padding added after overlap computation.
  @MainActor
  public func overlapHeight(
    in view: UIView,
    subtractSafeAreaBottom: Bool = true,
    additionalBottomInset: CGFloat = 0
  ) -> CGFloat {
    guard isVisible else { return 0 }
    let endInView = endFrame(in: view)
    let intersection = view.bounds.intersection(endInView)
    let rawHeight = intersection.isNull ? 0 : intersection.height
    let safeBottom = subtractSafeAreaBottom ? view.safeAreaInsets.bottom : 0
    return max(0, rawHeight - safeBottom + additionalBottomInset)
  }
}
