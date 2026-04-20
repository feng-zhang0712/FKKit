//
// FKBadgeUIKitExtensions.swift
//

import UIKit

public extension UIButton {
  /// Shortcut to the shared UIView-based badge controller.
  @MainActor var fk_badgeController: FKBadgeController { fk_badge }
}

public extension UILabel {
  /// Shortcut to the shared UIView-based badge controller.
  @MainActor var fk_badgeController: FKBadgeController { fk_badge }
}

public extension UIImageView {
  /// Shortcut to the shared UIView-based badge controller.
  @MainActor var fk_badgeController: FKBadgeController { fk_badge }
}
