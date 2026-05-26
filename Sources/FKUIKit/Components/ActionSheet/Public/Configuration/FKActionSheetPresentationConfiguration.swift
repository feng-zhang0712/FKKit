import UIKit

/// Tunables for how the action sheet modal is presented.
public struct FKActionSheetPresentationConfiguration: Equatable, Sendable {
  /// Placement of the action list (bottom sheet, centered card, or popover).
  public var style: FKActionSheetPresentationStyle
  /// Whether tapping the dimmed backdrop dismisses the sheet.
  ///
  /// Applies to ``FKActionSheetPresentationStyle/bottom`` and ``FKActionSheetPresentationStyle/centered``.
  /// Popovers use system outside-tap behavior when adapted; this flag is ignored for `.popover`.
  public var allowsTapOutsideDismiss: Bool
  /// Backdrop dim alpha (`0...1`) for bottom and centered styles.
  public var backdropAlpha: CGFloat
  /// Panel corner radius. Bottom style rounds the top edge only; centered/popover round all corners.
  public var cornerRadius: CGFloat
  /// Maximum panel width for bottom and centered layouts.
  public var maxPanelWidth: CGFloat
  /// Horizontal inset from the screen edge for bottom and centered layouts.
  ///
  /// Defaults to `0` (full-width bottom sheet). Use a positive value (for example `12`) for a floating card look.
  public var horizontalInset: CGFloat
  /// Minimum popover width when ``style`` is ``FKActionSheetPresentationStyle/popover``.
  public var popoverMinimumWidth: CGFloat
  /// Maximum scrollable content height as a fraction of the screen height.
  public var maximumFitContentHeightFraction: CGFloat
  /// Hard cap on scrollable content height (points) before the list scrolls inside the sheet.
  public var maximumPanelHeight: CGFloat?
  /// Shadow applied to the sheet panel.
  public var containerShadow: FKLayerShadowStyle
  /// When `true`, uses a shorter transition while Reduce Motion is enabled.
  public var respectsReduceMotion: Bool

  /// Default bottom action sheet (HIG-style).
  public static let `default` = FKActionSheetPresentationConfiguration()

  /// Centered card on a dimmed backdrop.
  public static let centered = FKActionSheetPresentationConfiguration(
    style: .centered,
    cornerRadius: 12,
    horizontalInset: 12,
    containerShadow: .custom(
      color: .black,
      opacity: 0.18,
      radius: 20,
      offset: CGSize(width: 0, height: 10)
    )
  )

  /// Popover anchored via ``FKActionSheetPresentationHostContext``.
  public static let popover = FKActionSheetPresentationConfiguration(
    style: .popover,
    allowsTapOutsideDismiss: false,
    backdropAlpha: 0,
    cornerRadius: 12
  )

  /// Creates presentation tuning parameters.
  public init(
    style: FKActionSheetPresentationStyle = .bottom,
    allowsTapOutsideDismiss: Bool = true,
    backdropAlpha: CGFloat = 0.35,
    cornerRadius: CGFloat = 0,
    maxPanelWidth: CGFloat = 414,
    horizontalInset: CGFloat = 0,
    popoverMinimumWidth: CGFloat = 320,
    maximumFitContentHeightFraction: CGFloat = 0.5,
    maximumPanelHeight: CGFloat? = nil,
    containerShadow: FKLayerShadowStyle = .none,
    respectsReduceMotion: Bool = true
  ) {
    self.style = style
    self.allowsTapOutsideDismiss = allowsTapOutsideDismiss
    self.backdropAlpha = min(max(backdropAlpha, 0), 1)
    self.cornerRadius = max(0, cornerRadius)
    self.maxPanelWidth = max(200, maxPanelWidth)
    self.horizontalInset = max(0, horizontalInset)
    self.popoverMinimumWidth = max(200, popoverMinimumWidth)
    self.maximumFitContentHeightFraction = min(max(maximumFitContentHeightFraction, 0.2), 1)
    self.maximumPanelHeight = maximumPanelHeight.map { max(0, $0) }
    self.containerShadow = containerShadow
    self.respectsReduceMotion = respectsReduceMotion
  }

  /// Resolved absolute content-height cap, if any.
  var resolvedMaximumPanelHeight: CGFloat? {
    maximumPanelHeight
  }

  /// Whether this style uses the custom modal presentation stack (backdrop + animator).
  var usesCustomModalPresentation: Bool {
    switch style {
    case .bottom, .centered:
      return true
    case .popover:
      return false
    }
  }
}
