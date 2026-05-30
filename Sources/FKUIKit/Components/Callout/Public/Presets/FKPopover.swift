import UIKit

/// Richer anchored panel built on ``FKCallout`` with popover defaults.
///
/// This is a custom UIKit bubble presenter, not `UIPopoverPresentationController` and not the legacy `FKBarPresentation` module.
public enum FKPopover {
  /// Default popover configuration (light card, manual dismiss).
  @MainActor
  public static var defaultConfiguration: FKCalloutConfiguration {
    get { FKCalloutCenter.shared.popoverConfiguration }
    set { FKCalloutCenter.shared.popoverConfiguration = newValue }
  }

  /// Menu/select preset configuration.
  @MainActor
  public static var menuConfiguration: FKCalloutConfiguration {
    get { FKCalloutCenter.shared.menuConfiguration }
    set { FKCalloutCenter.shared.menuConfiguration = newValue }
  }

  /// Whether a popover or other callout is visible.
  @MainActor
  public static var isPresenting: Bool {
    FKCallout.isPresenting
  }

  /// Shows title and body inside a popover bubble.
  @MainActor
  @discardableResult
  public static func show(
    title: String,
    message: String,
    anchoredTo anchor: UIView,
    sourceRect: CGRect? = nil,
    placement: FKCalloutPlacement = .automatic,
    configuration: FKCalloutConfiguration? = nil,
    hooks: FKCalloutLifecycleHooks = .init()
  ) -> FKCalloutHandle? {
    let resolved = FKCalloutConfiguration.resolvingPreset(
      configuration,
      default: defaultConfiguration,
      placement: placement,
      kind: .popover
    )
    return FKCallout.show(
      content: .titleSubtitle(title: title, message: message),
      anchoredTo: anchor,
      sourceRect: sourceRect,
      configuration: resolved,
      hooks: hooks
    )
  }

  /// Shows a split header panel popover (colored header + body).
  @MainActor
  @discardableResult
  public static func show(
    header: FKCalloutHeaderPanel,
    body: String,
    anchoredTo anchor: UIView,
    sourceRect: CGRect? = nil,
    placement: FKCalloutPlacement = .automatic,
    configuration: FKCalloutConfiguration? = nil,
    hooks: FKCalloutLifecycleHooks = .init()
  ) -> FKCalloutHandle? {
    let resolved = FKCalloutConfiguration.resolvingPreset(
      configuration,
      default: defaultConfiguration,
      placement: placement,
      kind: .popover
    )
    return FKCallout.show(
      content: .headerPanel(header: header, body: body),
      anchoredTo: anchor,
      sourceRect: sourceRect,
      configuration: resolved,
      hooks: hooks
    )
  }

  /// Shows plain message content in a popover bubble.
  @MainActor
  @discardableResult
  public static func show(
    message: String,
    anchoredTo anchor: UIView,
    sourceRect: CGRect? = nil,
    placement: FKCalloutPlacement = .automatic,
    configuration: FKCalloutConfiguration? = nil,
    hooks: FKCalloutLifecycleHooks = .init()
  ) -> FKCalloutHandle? {
    let resolved = FKCalloutConfiguration.resolvingPreset(
      configuration,
      default: defaultConfiguration,
      placement: placement,
      kind: .popover
    )
    return FKCallout.show(
      content: .message(message),
      anchoredTo: anchor,
      sourceRect: sourceRect,
      configuration: resolved,
      hooks: hooks
    )
  }

  /// Shows message content with footer actions (for example "Learn more").
  ///
  /// Map handlers by ``FKCalloutAction/id``; ``FKCalloutAction/title`` keys remain supported for legacy call sites.
  @MainActor
  @discardableResult
  public static func show(
    message: String,
    actions: [FKCalloutAction],
    actionHandlers: [String: @MainActor () -> Void],
    anchoredTo anchor: UIView,
    sourceRect: CGRect? = nil,
    placement: FKCalloutPlacement = .automatic,
    configuration: FKCalloutConfiguration? = nil,
    hooks: FKCalloutLifecycleHooks = .init()
  ) -> FKCalloutHandle? {
    var builder = FKCalloutBuilder(
      sourceRect: sourceRect,
      content: .messageWithActions(message: message, actions: actions),
      configuration: FKCalloutConfiguration.resolvingPreset(
        configuration,
        default: defaultConfiguration,
        placement: placement,
        kind: .popover
      ),
      hooks: hooks,
      actionHandlers: actionHandlers
    )
    builder.anchorView = anchor
    return FKCallout.show(builder: builder)
  }

  /// Shows an onboarding/coach-mark popover with optional close and primary action.
  @MainActor
  @discardableResult
  public static func showCoachMark(
    _ content: FKCalloutCoachMarkContent,
    anchoredTo anchor: UIView,
    sourceRect: CGRect? = nil,
    placement: FKCalloutPlacement = .bottom,
    primaryAction: (@MainActor () -> Void)? = nil,
    onClose: (@MainActor () -> Void)? = nil,
    configuration: FKCalloutConfiguration? = nil,
    hooks: FKCalloutLifecycleHooks = .init()
  ) -> FKCalloutHandle? {
    var builder = FKCalloutBuilder(
      sourceRect: sourceRect,
      content: .coachMark(content),
      configuration: {
        var resolved = FKCalloutConfiguration.resolvingPreset(
          configuration,
          default: defaultConfiguration,
          placement: placement,
          kind: .popover
        )
        if configuration == nil {
          resolved.backdrop = FKCalloutBackdropStyle(showsDimmedBackdrop: true, spotlightsAnchor: true)
        }
        return resolved
      }(),
      hooks: hooks,
      actionHandlers: primaryAction.map { [content.primaryActionTitle: $0] } ?? [:],
      closeHandler: onClose
    )
    builder.anchorView = anchor
    return FKCallout.show(builder: builder)
  }

  /// Shows a sectioned menu popover (dropdown/action menu).
  @MainActor
  @discardableResult
  public static func showMenu(
    _ menu: FKCalloutMenu,
    anchoredTo anchor: UIView,
    sourceRect: CGRect? = nil,
    placement: FKCalloutPlacement = .bottomLeading,
    onSelect: (@MainActor (FKCalloutMenuItem) -> Void)? = nil,
    configuration: FKCalloutConfiguration? = nil,
    hooks: FKCalloutLifecycleHooks = .init()
  ) -> FKCalloutHandle? {
    var builder = FKCalloutBuilder(
      sourceRect: sourceRect,
      content: .menu(menu),
      configuration: FKCalloutConfiguration.resolvingPreset(
        configuration,
        default: menuConfiguration,
        placement: placement,
        kind: .popover
      ),
      hooks: hooks,
      menuSelectionHandler: onSelect
    )
    builder.anchorView = anchor
    return FKCallout.show(builder: builder)
  }

  /// Shows custom UIKit content inside a popover bubble.
  @MainActor
  @discardableResult
  public static func show(
    customView: @escaping @MainActor () -> UIView,
    anchoredTo anchor: UIView,
    sourceRect: CGRect? = nil,
    placement: FKCalloutPlacement = .automatic,
    configuration: FKCalloutConfiguration? = nil,
    hooks: FKCalloutLifecycleHooks = .init()
  ) -> FKCalloutHandle? {
    let resolved = FKCalloutConfiguration.resolvingPreset(
      configuration,
      default: defaultConfiguration,
      placement: placement,
      kind: .popover
    )
    return FKCallout.show(
      content: .customView(customView),
      anchoredTo: anchor,
      sourceRect: sourceRect,
      configuration: resolved,
      hooks: hooks
    )
  }

  /// Dismisses every active callout session (including concurrent presentations).
  @MainActor
  public static func dismissActive(reason: FKCalloutDismissReason = .manual, animated: Bool = true) {
    FKCallout.dismissActive(reason: reason, animated: animated)
  }

  /// Dismisses a specific popover by handle.
  @MainActor
  public static func dismiss(_ handle: FKCalloutHandle, reason: FKCalloutDismissReason = .manual, animated: Bool = true) {
    handle.dismiss(reason: reason, animated: animated)
  }
}
