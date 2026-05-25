import UIKit

/// Tunables for how the action sheet is hosted by ``FKPresentationController``.
public struct FKActionSheetPresentationConfiguration: Equatable, Sendable {
  /// Whether tapping the dimmed backdrop dismisses the sheet.
  public var allowsTapOutsideDismiss: Bool
  /// Whether swipe-to-dismiss is enabled on the hosted sheet.
  ///
  /// Defaults to `false` so scrolling the action list does not accidentally dismiss the sheet.
  /// Set to `true` when you want sheet-level swipe dismissal.
  public var allowsSwipeDismiss: Bool
  /// Backdrop dim alpha (`0...1`).
  public var backdropAlpha: CGFloat
  /// Container top corner radius.
  public var cornerRadius: CGFloat
  /// Maximum scrollable content height as a fraction of the container when using `.fitContent`.
  ///
  /// Used when ``maximumPanelHeight`` is `nil`. Defaults to `0.5` so long lists scroll instead of filling the screen.
  public var maximumFitContentHeightFraction: CGFloat
  /// Hard cap on scrollable content height (points) before the list scrolls inside the sheet.
  ///
  /// When set, the effective cap is `min(maximumPanelHeight, fractionCap)`.
  public var maximumPanelHeight: CGFloat?
  /// Legacy alias for ``maximumPanelHeight``; when both are set, ``maximumPanelHeight`` wins.
  public var maximumContentHeight: CGFloat?
  /// Overrides ``FKPresentationConfiguration/cornerRadius`` shadow; `.none` is typical for action sheets.
  public var containerShadow: FKLayerShadowStyle
  /// When `true`, uses a shorter fade preset while Reduce Motion is enabled.
  public var respectsReduceMotion: Bool

  /// Action-sheet-friendly presentation defaults (single `fitContent` detent, no grabber).
  public static let `default` = FKActionSheetPresentationConfiguration()

  /// Creates presentation tuning parameters.
  public init(
    allowsTapOutsideDismiss: Bool = true,
    allowsSwipeDismiss: Bool = false,
    backdropAlpha: CGFloat = 0.35,
    cornerRadius: CGFloat = 0,
    maximumFitContentHeightFraction: CGFloat = 0.5,
    maximumPanelHeight: CGFloat? = nil,
    maximumContentHeight: CGFloat? = nil,
    containerShadow: FKLayerShadowStyle = .none,
    respectsReduceMotion: Bool = true
  ) {
    self.allowsTapOutsideDismiss = allowsTapOutsideDismiss
    self.allowsSwipeDismiss = allowsSwipeDismiss
    self.backdropAlpha = min(max(backdropAlpha, 0), 1)
    self.cornerRadius = max(0, cornerRadius)
    self.maximumFitContentHeightFraction = min(max(maximumFitContentHeightFraction, 0.2), 1)
    self.maximumPanelHeight = maximumPanelHeight.map { max(0, $0) }
    self.maximumContentHeight = maximumContentHeight.map { max(0, $0) }
    self.containerShadow = containerShadow
    self.respectsReduceMotion = respectsReduceMotion
  }

  /// Resolved absolute content-height cap, if any.
  var resolvedMaximumPanelHeight: CGFloat? {
    maximumPanelHeight ?? maximumContentHeight
  }
}

public extension FKActionSheetPresentationConfiguration {
  /// Optional transform applied to the generated ``FKPresentationConfiguration`` before presentation.
  ///
  /// Use this to access advanced presentation options without duplicating factory defaults.
  ///
  /// - Important: Must be `@MainActor` safe. Capture presenters weakly.
  typealias ConfigurationTransform = @MainActor (FKPresentationConfiguration) -> FKPresentationConfiguration
}
