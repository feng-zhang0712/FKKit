import UIKit

/// Core presenter for anchored callout bubbles (tooltip and popover presets build on this).
public enum FKCallout {
  /// Baseline configuration merged into each request unless overridden.
  @MainActor
  public static var defaultConfiguration: FKCalloutConfiguration {
    get { FKCalloutCenter.shared.defaultConfiguration }
    set { FKCalloutCenter.shared.defaultConfiguration = newValue }
  }

  /// `true` when a callout is attached to the key window.
  @MainActor
  public static var isPresenting: Bool {
    FKCalloutCenter.shared.isPresenting
  }

  /// Presents a callout described by ``FKCalloutBuilder``.
  ///
  /// - Parameter builder: Anchor, content, and configuration. Set ``FKCalloutBuilder/anchorView`` on the main actor.
  /// - Returns: A handle when presentation succeeds; `nil` when the anchor is not in a window.
  @MainActor
  @discardableResult
  public static func show(builder: FKCalloutBuilder) -> FKCalloutHandle? {
    let id = UUID()
    guard FKCalloutCenter.shared.show(builder: builder, id: id) != nil else { return nil }
    return FKCalloutHandle(id: id)
  }

  /// Presents a callout or updates the visible callout anchored to the same view.
  @MainActor
  @discardableResult
  public static func showOrUpdate(builder: FKCalloutBuilder) -> FKCalloutHandle? {
    guard let anchor = builder.anchorView else { return nil }
    if let existing = FKCalloutCenter.shared.presentation(forAnchor: anchor) {
      let handle = FKCalloutHandle(id: existing.id)
      guard handle.update(content: builder.content, configuration: builder.configuration) else {
        return show(builder: builder)
      }
      return handle
    }
    return show(builder: builder)
  }

  /// Presents a callout anchored to a view.
  @MainActor
  @discardableResult
  public static func show(
    content: FKCalloutContent,
    anchoredTo anchor: UIView,
    sourceRect: CGRect? = nil,
    configuration: FKCalloutConfiguration = defaultConfiguration,
    hooks: FKCalloutLifecycleHooks = .init()
  ) -> FKCalloutHandle? {
    var builder = FKCalloutBuilder(
      content: content,
      configuration: configuration,
      hooks: hooks
    )
    builder.anchorView = anchor
    builder.sourceRect = sourceRect
    return show(builder: builder)
  }

  /// Dismisses the callout with the given identifier.
  @MainActor
  public static func dismiss(
    _ id: UUID,
    reason: FKCalloutDismissReason = .manual,
    animated: Bool = true
  ) {
    FKCalloutCenter.shared.dismiss(id: id, reason: reason, animated: animated)
  }

  /// Dismisses whichever callout is currently visible.
  @MainActor
  public static func dismissActive(reason: FKCalloutDismissReason = .manual, animated: Bool = true) {
    FKCalloutCenter.shared.dismissActive(reason: reason, animated: animated)
  }

  /// Updates content for a visible callout.
  @MainActor
  @discardableResult
  public static func update(
    _ id: UUID,
    content: FKCalloutContent,
    configuration: FKCalloutConfiguration? = nil
  ) -> Bool {
    FKCalloutCenter.shared.update(id: id, content: content, configuration: configuration)
  }
}
