import UIKit

/// Resolves which window or scene hosts an action sheet when no explicit presenter is supplied.
public struct FKActionSheetPresentationHostContext {
  /// Explicit presenter. When set, `window` and `windowScene` are ignored.
  public var presenter: FKWeakReference<UIViewController>?
  /// Host window used to resolve the top presenter when `presenter` is `nil`.
  public var window: FKWeakReference<UIWindow>?
  /// Host scene used to resolve the top presenter when `presenter` is `nil`.
  public var windowScene: FKWeakReference<UIWindowScene>?

  /// Creates a host context with an explicit presenter.
  public init(presenter: UIViewController) {
    self.presenter = FKWeakReference(presenter)
    self.window = nil
    self.windowScene = nil
  }

  /// Creates a host context targeting a window.
  public init(window: UIWindow) {
    self.presenter = nil
    self.window = FKWeakReference(window)
    self.windowScene = nil
  }

  /// Creates a host context targeting a window scene.
  public init(windowScene: UIWindowScene) {
    self.presenter = nil
    self.window = nil
    self.windowScene = FKWeakReference(windowScene)
  }

  /// Creates an empty context (falls back to the app key window).
  public init() {
    self.presenter = nil
    self.window = nil
    self.windowScene = nil
  }
}
