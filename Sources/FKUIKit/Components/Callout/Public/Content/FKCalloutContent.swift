import UIKit

/// Text or custom UI hosted inside a callout bubble.
public enum FKCalloutContent: @unchecked Sendable {
  /// Single-line or multi-line label text.
  case message(String)
  /// Title with supporting body copy (popover-friendly).
  case titleSubtitle(title: String, message: String)
  /// Leading icon with multi-line message.
  case iconMessage(icon: FKCalloutIcon, message: String)
  /// Message with one or more footer actions (for example "Learn more").
  case messageWithActions(message: String, actions: [FKCalloutAction])
  /// Colored header strip with body text beneath.
  case headerPanel(header: FKCalloutHeaderPanel, body: String)
  /// Onboarding/coach-mark layout with optional close and primary action.
  case coachMark(FKCalloutCoachMarkContent)
  /// Sectioned menu list (dropdown/action menu).
  case menu(FKCalloutMenu)
  /// Custom UIKit content evaluated on the main actor at presentation time.
  case customView(@MainActor () -> UIView)
}

/// Bundles anchor, content, configuration, lifecycle hooks, and interaction handlers.
public struct FKCalloutBuilder: @unchecked Sendable {
  /// Weakly held at presentation time on the main actor.
  @MainActor public var anchorView: UIView?
  /// Optional rect in `anchorView` coordinates; `nil` uses `anchorView.bounds`.
  public var sourceRect: CGRect?
  /// Bubble payload.
  public var content: FKCalloutContent
  /// Per-request display and interaction options.
  public var configuration: FKCalloutConfiguration
  /// Show and dismiss callbacks.
  public var hooks: FKCalloutLifecycleHooks
  /// Action handlers keyed by ``FKCalloutAction/id`` (``FKCalloutAction/title`` is supported for legacy call sites).
  public var actionHandlers: [String: @MainActor () -> Void]
  /// Called when the user selects a menu row.
  public var menuSelectionHandler: (@MainActor (FKCalloutMenuItem) -> Void)?
  /// Called when the coach-mark close button is tapped.
  public var closeHandler: (@MainActor () -> Void)?
  /// Optional custom beak view; when set, replaces the built-in path beak. Sized and positioned by the layout engine.
  public var customBeakViewProvider: (@MainActor () -> UIView)?

  /// Creates a builder. Set ``anchorView`` on the main actor before calling ``FKCallout/show(builder:)``.
  @MainActor
  public init(
    anchorView: UIView? = nil,
    sourceRect: CGRect? = nil,
    content: FKCalloutContent,
    configuration: FKCalloutConfiguration = .init(),
    hooks: FKCalloutLifecycleHooks = .init(),
    actionHandlers: [String: @MainActor () -> Void] = [:],
    menuSelectionHandler: (@MainActor (FKCalloutMenuItem) -> Void)? = nil,
    closeHandler: (@MainActor () -> Void)? = nil,
    customBeakViewProvider: (@MainActor () -> UIView)? = nil
  ) {
    self.anchorView = anchorView
    self.sourceRect = sourceRect
    self.content = content
    self.configuration = configuration
    self.hooks = hooks
    self.actionHandlers = actionHandlers
    self.menuSelectionHandler = menuSelectionHandler
    self.closeHandler = closeHandler
    self.customBeakViewProvider = customBeakViewProvider
  }
}

/// Lifecycle callbacks for one callout request.
public struct FKCalloutLifecycleHooks: Sendable {
  /// Called immediately before the enter animation starts.
  public var willShow: (@MainActor (UUID) -> Void)?
  /// Called when the enter animation completes.
  public var didShow: (@MainActor (UUID) -> Void)?
  /// Called immediately before dismissal begins.
  public var willDismiss: (@MainActor (UUID, FKCalloutDismissReason) -> Void)?
  /// Called after the overlay is removed.
  public var didDismiss: (@MainActor (UUID, FKCalloutDismissReason) -> Void)?

  /// Creates lifecycle hooks.
  public init(
    willShow: (@MainActor (UUID) -> Void)? = nil,
    didShow: (@MainActor (UUID) -> Void)? = nil,
    willDismiss: (@MainActor (UUID, FKCalloutDismissReason) -> Void)? = nil,
    didDismiss: (@MainActor (UUID, FKCalloutDismissReason) -> Void)? = nil
  ) {
    self.willShow = willShow
    self.didShow = didShow
    self.willDismiss = willDismiss
    self.didDismiss = didDismiss
  }
}
