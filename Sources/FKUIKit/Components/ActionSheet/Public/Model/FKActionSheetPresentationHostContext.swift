import UIKit

/// Resolves which window or scene hosts an action sheet when no explicit presenter is supplied.
public struct FKActionSheetPresentationHostContext {
  /// Explicit presenter. When set, `window` and `windowScene` are ignored.
  public var presenter: FKWeakReference<UIViewController>?
  /// Host window used to resolve the top presenter when `presenter` is `nil`.
  public var window: FKWeakReference<UIWindow>?
  /// Host scene used to resolve the top presenter when `presenter` is `nil`.
  public var windowScene: FKWeakReference<UIWindowScene>?

  /// Source view for ``FKActionSheetPresentationStyle/popover`` presentation.
  public var popoverSourceView: FKWeakReference<UIView>?
  /// Source rect in `popoverSourceView` coordinates. When `nil`, `popoverSourceView.bounds` is used.
  public var popoverSourceRect: CGRect?
  /// Bar button anchor for popover presentation (alternative to ``popoverSourceView``).
  public var popoverBarButtonItem: FKWeakReference<UIBarButtonItem>?
  /// Permitted arrow directions when presenting as a popover.
  public var permittedPopoverArrowDirections: UIPopoverArrowDirection = .any

  /// Creates a host context with an explicit presenter.
  public init(presenter: UIViewController) {
    self.presenter = FKWeakReference(presenter)
    self.window = nil
    self.windowScene = nil
  }

  /// Creates a host context for popover presentation from a source view.
  public init(
    presenter: UIViewController,
    popoverSource sourceView: UIView,
    sourceRect: CGRect? = nil,
    permittedArrowDirections: UIPopoverArrowDirection = .any
  ) {
    self.presenter = FKWeakReference(presenter)
    self.popoverSourceView = FKWeakReference(sourceView)
    self.popoverSourceRect = sourceRect
    self.permittedPopoverArrowDirections = permittedArrowDirections
    self.window = nil
    self.windowScene = nil
  }

  /// Creates a host context for popover presentation from a bar button item.
  public init(
    presenter: UIViewController,
    popoverBarButtonItem barButtonItem: UIBarButtonItem,
    permittedArrowDirections: UIPopoverArrowDirection = .any
  ) {
    self.presenter = FKWeakReference(presenter)
    self.popoverBarButtonItem = FKWeakReference(barButtonItem)
    self.permittedPopoverArrowDirections = permittedArrowDirections
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

  /// Resolved popover source rect in the source view's coordinate space.
  var resolvedPopoverSourceRect: CGRect {
    if let popoverSourceRect {
      return popoverSourceRect
    }
    return popoverSourceView?.object?.bounds ?? .zero
  }

  /// Whether a popover anchor is configured.
  var hasPopoverAnchor: Bool {
    popoverSourceView?.object != nil || popoverBarButtonItem?.object != nil
  }
}
