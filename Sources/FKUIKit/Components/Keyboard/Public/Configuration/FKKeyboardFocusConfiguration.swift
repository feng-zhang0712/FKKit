import CoreGraphics
import Foundation
import UIKit

/// Configuration for ``FKKeyboardFocusScroller``.
public struct FKKeyboardFocusConfiguration: Equatable, Sendable {
  /// Extra padding kept visible above the focused view inside the scroll view.
  public var additionalTopInset: CGFloat

  /// Distance kept between the focused view’s bottom and the unobscured visible bottom.
  ///
  /// Matches IQKeyboardManager’s `keyboardDistanceFromTextField` (default `10`).
  public var keyboardDistanceFromFocusedView: CGFloat

  /// When `true`, positions the focused field just above the keyboard even if it was already
  /// visible (IQKeyboardManager-like). When `false` (default), only scrolls when the keyboard
  /// would cover the field (or violate ``keyboardDistanceFromFocusedView``).
  public var alignsFocusedViewToKeyboard: Bool

  /// When `true`, scrolling uses the keyboard animation duration / curve when available.
  public var animatesAlongsideKeyboard: Bool

  /// When `true`, the scroller owns and starts an internal ``FKKeyboardObserver``.
  public var observesKeyboardAutomatically: Bool

  /// When `true` (default), keyboard overlap is written into the scroll view’s bottom
  /// `contentInset`. Set `false` when another owner already manages bottom inset (for example
  /// ``FKKeyboardLayout`` pinning the scroll view above a composer) — scrolling still uses the
  /// obscured band for geometry.
  public var appliesKeyboardBottomInset: Bool

  /// Creates a focus-scrolling configuration.
  public init(
    additionalTopInset: CGFloat = 12,
    keyboardDistanceFromFocusedView: CGFloat = 10,
    alignsFocusedViewToKeyboard: Bool = false,
    animatesAlongsideKeyboard: Bool = true,
    observesKeyboardAutomatically: Bool = true,
    appliesKeyboardBottomInset: Bool = true
  ) {
    self.additionalTopInset = additionalTopInset
    self.keyboardDistanceFromFocusedView = keyboardDistanceFromFocusedView
    self.alignsFocusedViewToKeyboard = alignsFocusedViewToKeyboard
    self.animatesAlongsideKeyboard = animatesAlongsideKeyboard
    self.observesKeyboardAutomatically = observesKeyboardAutomatically
    self.appliesKeyboardBottomInset = appliesKeyboardBottomInset
  }
}
