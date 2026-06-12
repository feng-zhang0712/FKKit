import UIKit

/// Options controlling how ``FKThemeRegistry/register(_:options:)`` applies a theme.
public struct FKThemeApplicationOptions: Sendable, Equatable {
  /// Posts ``FKThemeRegistry/themeDidChangeNotification`` when `true`.
  public var postsNotification: Bool
  /// Requests layout on visible windows when `true`.
  public var refreshesVisibleWindows: Bool
  /// Updates opt-in component defaults such as ``FKButtonGlobalStyle`` when `true`.
  public var appliesComponentDefaults: Bool

  /// Creates application options.
  public init(
    postsNotification: Bool = true,
    refreshesVisibleWindows: Bool = true,
    appliesComponentDefaults: Bool = true
  ) {
    self.postsNotification = postsNotification
    self.refreshesVisibleWindows = refreshesVisibleWindows
    self.appliesComponentDefaults = appliesComponentDefaults
  }
}

/// Views that refresh when the active theme changes.
@MainActor
public protocol FKThemeAware: AnyObject {
  /// Applies the supplied theme snapshot.
  func apply(theme: FKTheme)
}

/// Process-wide active theme registry.
@MainActor
public enum FKThemeRegistry {
  private static var storedTheme: FKTheme = .default

  /// The active theme snapshot. Assigning is equivalent to ``register(_:options:)`` with default options.
  public static var current: FKTheme {
    get { storedTheme }
    set { register(newValue) }
  }

  /// Posted after ``register(_:options:)`` when `options.postsNotification` is `true`.
  public static let themeDidChangeNotification = Notification.Name("FKThemeRegistry.themeDidChange")

  /// Registers `theme`, optionally syncing component defaults and broadcasting the change.
  public static func register(_ theme: FKTheme, options: FKThemeApplicationOptions = .init()) {
    storedTheme = theme
    if options.appliesComponentDefaults {
      FKThemeComponentIntegration.applyComponentDefaults(from: theme)
    }
    if options.postsNotification {
      NotificationCenter.default.post(name: themeDidChangeNotification, object: theme)
    }
    if options.refreshesVisibleWindows {
      refreshVisibleWindows()
    }
  }

  private static func refreshVisibleWindows() {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    for scene in scenes {
      for window in scene.windows where window.isHidden == false {
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
      }
    }
  }
}
