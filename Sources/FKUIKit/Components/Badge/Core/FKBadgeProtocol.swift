//
// FKBadgeProtocol.swift
//

import Foundation

/// Abstract contract for badge presentation APIs.
///
/// The protocol enables decoupling UI modules from a specific badge implementation.
@MainActor
public protocol FKBadgePresenting: AnyObject {
  /// Displays a pure dot badge.
  func showDot(animated: Bool, animation: FKBadgeAnimation)
  /// Displays a numeric badge.
  func showCount(_ count: Int, animated: Bool, animation: FKBadgeAnimation)
  /// Displays a text badge.
  func showText(_ text: String, animated: Bool, animation: FKBadgeAnimation)
  /// Clears content and hides the badge.
  func clear(animated: Bool)
}

@MainActor
extension FKBadgeController: FKBadgePresenting {}
