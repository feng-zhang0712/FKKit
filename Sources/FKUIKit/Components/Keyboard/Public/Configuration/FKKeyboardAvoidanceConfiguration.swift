import CoreGraphics
import Foundation
import UIKit

/// Configuration for ``FKKeyboardAvoidanceController``.
public struct FKKeyboardAvoidanceConfiguration: Equatable, Sendable {
  /// Avoidance strategy applied when the keyboard overlaps the host.
  public var strategy: FKKeyboardAvoidanceStrategy

  /// Extra bottom padding added on top of computed keyboard overlap (scroll `contentInset.bottom`).
  public var additionalBottomInset: CGFloat

  /// Distance kept between the focused view’s bottom and the unobscured visible bottom.
  ///
  /// Matches IQKeyboardManager’s `keyboardDistanceFromTextField` (default `10`).
  public var keyboardDistanceFromFocusedView: CGFloat

  /// When `true`, safe-area bottom inset is subtracted from keyboard intersection height.
  public var subtractSafeAreaBottom: Bool

  /// When `true`, the controller owns and starts an internal ``FKKeyboardObserver``.
  public var observesKeyboardAutomatically: Bool

  /// When `true` and strategy resolves to content insets, scrolls the first responder so it stays
  /// in the unobscured band (see ``alignsFocusedViewToKeyboard``).
  public var scrollsFocusedViewIntoVisibleArea: Bool

  /// When `true`, pins the focused field just above the keyboard (IQKeyboardManager-like), even if
  /// it was already fully visible. When `false` (default), only scrolls the minimum amount needed
  /// when the keyboard would cover the field (or violate ``keyboardDistanceFromFocusedView``).
  public var alignsFocusedViewToKeyboard: Bool

  /// Creates an avoidance configuration.
  public init(
    strategy: FKKeyboardAvoidanceStrategy = .adjustContentInsets,
    additionalBottomInset: CGFloat = 0,
    keyboardDistanceFromFocusedView: CGFloat = 10,
    subtractSafeAreaBottom: Bool = true,
    observesKeyboardAutomatically: Bool = true,
    scrollsFocusedViewIntoVisibleArea: Bool = true,
    alignsFocusedViewToKeyboard: Bool = false
  ) {
    self.strategy = strategy
    self.additionalBottomInset = additionalBottomInset
    self.keyboardDistanceFromFocusedView = keyboardDistanceFromFocusedView
    self.subtractSafeAreaBottom = subtractSafeAreaBottom
    self.observesKeyboardAutomatically = observesKeyboardAutomatically
    self.scrollsFocusedViewIntoVisibleArea = scrollsFocusedViewIntoVisibleArea
    self.alignsFocusedViewToKeyboard = alignsFocusedViewToKeyboard
  }
}
