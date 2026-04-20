//
// FKBadgeManager.swift
//

import UIKit

/// Global badge manager for app-wide style and behavior.
///
/// Use `shared` to set baseline defaults once (for example in app launch), while still allowing
/// each `FKBadgeController` to override its own configuration independently.
@MainActor
public final class FKBadgeManager {
  /// Shared singleton manager.
  public static let shared = FKBadgeManager()

  /// Baseline configuration used by newly created badge controllers.
  public var defaultConfiguration: FKBadgeConfiguration {
    didSet { FKBadge.defaultConfiguration = defaultConfiguration }
  }

  private init() {
    self.defaultConfiguration = FKBadge.defaultConfiguration
  }

  /// Hides all active badges currently tracked by the registry.
  public func hideAll(animated: Bool = false) {
    FKBadge.hideAllBadges(animated: animated)
  }

  /// Restores visibility behavior for all tracked badges.
  public func restoreAll(animated: Bool = false) {
    FKBadge.restoreAllBadges(animated: animated)
  }
}
