import UIKit

/// Short-lived anchored hint built on ``FKCallout`` with tooltip defaults.
public enum FKTooltip {
  /// Default tooltip configuration (dark compact bubble, auto-dismiss).
  @MainActor
  public static var defaultConfiguration: FKCalloutConfiguration {
    get { FKCalloutCenter.shared.tooltipConfiguration }
    set { FKCalloutCenter.shared.tooltipConfiguration = newValue }
  }

  /// Whether a tooltip/callout is visible.
  @MainActor
  public static var isPresenting: Bool {
    FKCallout.isPresenting
  }

  /// Shows a text tooltip anchored to a view.
  @MainActor
  @discardableResult
  public static func show(
    _ message: String,
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
      kind: .tooltip
    )
    return FKCallout.show(
      content: .message(message),
      anchoredTo: anchor,
      sourceRect: sourceRect,
      configuration: resolved,
      hooks: hooks
    )
  }

  /// Shows an icon + message tooltip.
  @MainActor
  @discardableResult
  public static func show(
    icon: FKCalloutIcon,
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
      kind: .tooltip
    )
    return FKCallout.show(
      content: .iconMessage(icon: icon, message: message),
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

  /// Dismisses a specific tooltip by handle.
  @MainActor
  public static func dismiss(_ handle: FKCalloutHandle, reason: FKCalloutDismissReason = .manual, animated: Bool = true) {
    handle.dismiss(reason: reason, animated: animated)
  }
}
