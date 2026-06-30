import UIKit

/// Configuration for `FKSheetPresentationConfiguration.Layout.anchor(_:)`.
///
/// Anchor-hosted presentations are hosted inside the existing view hierarchy (instead of a modal
/// `UIPresentationController` container). This enables "menu-like" overlays that appear attached
/// to a navigation bar, toolbar, or any in-page anchor view, while keeping the anchor visually above
/// the overlay (optional) and limiting the mask coverage (optional).
///
/// This mode is intended to replace ad-hoc dropdown implementations with a consistent, reusable API
/// while remaining resilient to layout changes (rotation, safe area changes, trait changes, and dynamic
/// anchor movement).
public struct FKAnchorConfiguration {
  /// Anchor geometry and expansion direction.
  ///
  /// This reuses `FKAnchor` so the mental model stays consistent with the anchor geometry model.
  public var anchor: FKAnchor

  /// Where the anchor overlay is inserted.
  public var hostStrategy: HostStrategy

  /// Policy controlling the overlay's z-order relative to the anchor.
  public var zOrderPolicy: ZOrderPolicy

  /// Policy controlling how much of the host is covered by the interaction mask.
  public var maskCoveragePolicy: MaskCoveragePolicy

  /// Reposition behavior when host or anchor geometry changes.
  public var repositionPolicy: RepositionPolicy

  /// Behavior when `present` is requested while this anchor scope already shows a popup.
  public var repeatPresentationPolicy: FKAnchorRepeatPresentationPolicy

  /// Creates an anchor-hosted configuration.
  public init(
    anchor: FKAnchor,
    hostStrategy: HostStrategy = .inSameSuperviewBelowAnchor,
    zOrderPolicy: ZOrderPolicy = .keepAnchorAbovePresentation,
    maskCoveragePolicy: MaskCoveragePolicy = .belowAnchorOnly,
    repositionPolicy: RepositionPolicy = .init(),
    repeatPresentationPolicy: FKAnchorRepeatPresentationPolicy = .replaceExisting()
  ) {
    self.anchor = anchor
    self.hostStrategy = hostStrategy
    self.zOrderPolicy = zOrderPolicy
    self.maskCoveragePolicy = maskCoveragePolicy
    self.repositionPolicy = repositionPolicy
    self.repeatPresentationPolicy = repeatPresentationPolicy
  }
}

public extension FKAnchorConfiguration {
  /// Strategy used to decide where to host the anchor overlay.
  enum HostStrategy {
    /// Inserts the overlay into the anchor's host view and keeps it below the anchor's direct child view.
    ///
    /// This matches the typical "dropdown attached to a navigation bar / toolbar" layering strategy:
    /// the anchor stays above, and the overlay is visually attached to the anchor edge.
    case inSameSuperviewBelowAnchor

    /// Inserts the overlay into a provided container view.
    ///
    /// Use this for complex hierarchies where the correct host is known in advance
    /// (for example a tab-bar filter strip hosted in a parent overlay container).
    ///
    /// Reposition passes re-attach the presentation layer when needed and keep the anchor
    /// above the overlay when `zOrderPolicy` is `.keepAnchorAbovePresentation`.
    case inProvidedContainer(FKWeakReference<UIView>)

    /// Inserts the overlay into a window-level container.
    ///
    /// This is useful when your anchor participates in complex transitions and you want a stable host.
    /// If no suitable window can be resolved at runtime, FK will fall back to the best-effort host.
    case inWindowLevel
  }

  /// Controls whether FK keeps the anchor above the anchor overlay.
  enum ZOrderPolicy {
    /// Ensures the anchor (or its direct host child) stays above the anchor overlay.
    ///
    /// This is the recommended default for anchor dropdown menus.
    case keepAnchorAbovePresentation

    /// No special z-order handling.
    case normal
  }

  /// Controls how much of the host area is covered by the interaction mask.
  enum MaskCoveragePolicy {
    /// Only covers the area *below* the anchor attachment line.
    ///
    /// This reduces accidental blocking of UI
    /// above the anchor (e.g. navigation bar items).
    case belowAnchorOnly

    /// Covers the full host bounds.
    case fullScreen
  }

  /// Reposition policy for anchor overlays.
  struct RepositionPolicy {
    /// Whether to listen to host layout changes.
    public var listensToLayoutChanges: Bool
    /// Whether to listen to trait collection changes.
    public var listensToTraitChanges: Bool
    /// Whether to listen to orientation changes.
    public var listensToOrientationChanges: Bool
    /// Debounce interval used to coalesce frequent changes.
    ///
    /// Anchor relayout is deferred while the presenting view controller has a modal
    /// child and is stabilized across two layout passes after the modal dismisses.
    public var debounceInterval: TimeInterval

    public init(
      listensToLayoutChanges: Bool = true,
      listensToTraitChanges: Bool = true,
      listensToOrientationChanges: Bool = true,
      debounceInterval: TimeInterval = 0
    ) {
      self.listensToLayoutChanges = listensToLayoutChanges
      self.listensToTraitChanges = listensToTraitChanges
      self.listensToOrientationChanges = listensToOrientationChanges
      self.debounceInterval = max(0, debounceInterval)
    }
  }
}
