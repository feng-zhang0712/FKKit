//
// UITabBarItem+FKBadge.swift
//

import UIKit

public extension UITabBarItem {
  /// Returns overlay badge controller when the tab bar item host view is available.
  ///
  /// This enables custom dot/text/count rendering beyond UIKit `badgeValue`.
  @MainActor
  var fk_badge: FKBadgeController? {
    fk_badgeHostView?.fk_badge
  }

  /// Applies the same overflow rules as `FKBadgeFormatter` to the system `badgeValue` string.
  func fk_setBadgeCount(_ count: Int?, maxDisplay: Int = 99, overflowSuffix: String = "+") {
    guard let count, count > 0 else {
      badgeValue = nil
      return
    }
    let configuration = FKBadgeConfiguration(maxDisplayCount: maxDisplay, overflowSuffix: overflowSuffix)
    badgeValue = FKBadgeFormatter.displayString(count: count, configuration: configuration)
  }

  /// One-line helper to show custom numeric badge as overlay.
  @MainActor
  func fk_showBadgeCount(_ count: Int, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showCount(count, animated: animated, animation: animation)
  }

  /// One-line helper to show custom text badge as overlay.
  @MainActor
  func fk_showBadgeText(_ text: String, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showText(text, animated: animated, animation: animation)
  }

  /// One-line helper to show pure red dot as overlay.
  @MainActor
  func fk_showBadgeDot(animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showDot(animated: animated, animation: animation)
  }

  /// One-line helper to clear both overlay and system badge text.
  @MainActor
  func fk_hideBadge(animated: Bool = false) {
    fk_badge?.clear(animated: animated)
    badgeValue = nil
  }
}

private extension UITabBarItem {
  var fk_badgeHostView: UIView? {
    value(forKey: "view") as? UIView
  }
}
