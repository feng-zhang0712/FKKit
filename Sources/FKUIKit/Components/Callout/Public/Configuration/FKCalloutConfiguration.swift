import UIKit

/// Interaction category used for default tuning (tooltip vs popover presets).
public enum FKCalloutKind: Sendable, Equatable {
  /// Short, transient hint with conservative width and auto-dismiss defaults.
  case tooltip
  /// Richer panel that stays until the user dismisses it or replaces it.
  case popover
}

/// Entrance and exit motion styles.
public enum FKCalloutAnimationStyle: Sendable, Equatable {
  /// Opacity only.
  case fade
  /// Opacity with a subtle scale.
  case fadeScale
}

/// Per-request configuration for anchored callouts.
public struct FKCalloutConfiguration: Sendable, Equatable {
  /// Tooltip vs popover defaults (width, auto-dismiss, interaction).
  public var kind: FKCalloutKind
  /// Bubble placement relative to the anchor. ``FKCalloutPlacement/automatic`` picks the best side at layout time.
  public var placement: FKCalloutPlacement
  /// Visual chrome.
  public var appearance: FKCalloutAppearance
  /// Gap between the anchor and the beak tip.
  public var anchorSpacing: CGFloat
  /// Maximum bubble width; height grows with content.
  public var maxWidth: CGFloat
  /// Interior padding around text or custom content (excluding beak inset).
  public var contentInsets: NSDirectionalEdgeInsets
  /// Body font for message-only content.
  public var font: UIFont
  /// Title font for ``FKCalloutContent/titleSubtitle(title:message:)``.
  public var titleFont: UIFont
  /// Enter/exit animation duration.
  public var animationDuration: TimeInterval
  /// Enter/exit animation style.
  public var animationStyle: FKCalloutAnimationStyle
  /// When `> 0`, automatically dismisses after this interval. `nil` keeps the callout until manual dismissal.
  public var autoDismissDuration: TimeInterval?
  /// Dismisses when the user taps outside the bubble.
  public var tapOutsideToDismiss: Bool
  /// When `true`, touches outside the bubble reach views behind the overlay.
  ///
  /// With ``tapOutsideToDismiss``, outside taps still dismiss the callout using a non-blocking
  /// window-level recognizer so underlying buttons and controls remain interactive.
  public var passesThroughOutsideTouches: Bool
  /// Posts a VoiceOver announcement when shown.
  public var accessibilityAnnouncementEnabled: Bool
  /// Optional announcement override; `nil` derives text from content.
  public var accessibilityAnnouncementOverride: String?
  /// When `true`, attempts the opposite placement if the preferred one does not fit the safe area.
  public var flipsPlacementWhenNeeded: Bool
  /// Aligns the bubble along the anchor edge (for example dropdowns aligned to the leading edge).
  public var anchorAlignment: FKCalloutAnchorAlignment
  /// Optional override for beak position along its edge.
  public var beakOffset: FKCalloutBeakOffset
  /// When `true`, the bubble width is at least the anchor width (common for select menus).
  public var matchesAnchorWidth: Bool
  /// Optional minimum bubble width independent of content measurement.
  public var minWidth: CGFloat?
  /// Extra inset applied outside the container safe area when clamping bubble position and width.
  public var screenEdgeMargin: CGFloat
  /// Maximum height of scrollable interior content (excluding beak). `nil` grows with content.
  public var maxContentHeight: CGFloat?
  /// Keyboard interaction while the callout is visible.
  public var keyboardAvoidance: FKCalloutKeyboardAvoidance
  /// Whether a new presentation replaces existing callouts or may be shown concurrently.
  public var presentationPolicy: FKCalloutPresentationPolicy
  /// Optional dimmed backdrop and anchor spotlight (common for coach marks).
  public var backdrop: FKCalloutBackdropStyle

  /// Creates configuration; use ``FKCalloutConfiguration/tooltipDefault(placement:)`` or ``popoverDefault(placement:)`` for presets.
  public init(
    kind: FKCalloutKind = .tooltip,
    placement: FKCalloutPlacement = .automatic,
    appearance: FKCalloutAppearance = .init(),
    anchorSpacing: CGFloat = 8,
    maxWidth: CGFloat = 280,
    contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12),
    font: UIFont = .preferredFont(forTextStyle: .subheadline),
    titleFont: UIFont = .preferredFont(forTextStyle: .headline),
    animationDuration: TimeInterval = 0.22,
    animationStyle: FKCalloutAnimationStyle = .fadeScale,
    autoDismissDuration: TimeInterval? = nil,
    tapOutsideToDismiss: Bool = true,
    passesThroughOutsideTouches: Bool = true,
    accessibilityAnnouncementEnabled: Bool = true,
    accessibilityAnnouncementOverride: String? = nil,
    flipsPlacementWhenNeeded: Bool = true,
    anchorAlignment: FKCalloutAnchorAlignment = .center,
    beakOffset: FKCalloutBeakOffset = .automatic,
    matchesAnchorWidth: Bool = false,
    minWidth: CGFloat? = nil,
    screenEdgeMargin: CGFloat = 12,
    maxContentHeight: CGFloat? = nil,
    keyboardAvoidance: FKCalloutKeyboardAvoidance = .relayout,
    presentationPolicy: FKCalloutPresentationPolicy = .replaceActive,
    backdrop: FKCalloutBackdropStyle = .init()
  ) {
    self.kind = kind
    self.placement = placement
    self.appearance = appearance
    self.anchorSpacing = anchorSpacing
    self.maxWidth = maxWidth
    self.contentInsets = contentInsets
    self.font = font
    self.titleFont = titleFont
    self.animationDuration = animationDuration
    self.animationStyle = animationStyle
    self.autoDismissDuration = autoDismissDuration
    self.tapOutsideToDismiss = tapOutsideToDismiss
    self.passesThroughOutsideTouches = passesThroughOutsideTouches
    self.accessibilityAnnouncementEnabled = accessibilityAnnouncementEnabled
    self.accessibilityAnnouncementOverride = accessibilityAnnouncementOverride
    self.flipsPlacementWhenNeeded = flipsPlacementWhenNeeded
    self.anchorAlignment = anchorAlignment
    self.beakOffset = beakOffset
    self.matchesAnchorWidth = matchesAnchorWidth
    self.minWidth = minWidth
    self.screenEdgeMargin = screenEdgeMargin
    self.maxContentHeight = maxContentHeight
    self.keyboardAvoidance = keyboardAvoidance
    self.presentationPolicy = presentationPolicy
    self.backdrop = backdrop
  }

  /// Tooltip preset: narrower width, short auto-dismiss, light style by default.
  public static func tooltipDefault(placement: FKCalloutPlacement = .automatic) -> FKCalloutConfiguration {
    FKCalloutConfiguration(
      kind: .tooltip,
      placement: placement,
      appearance: FKCalloutAppearance(style: .dark, showsShadow: false),
      anchorSpacing: 6,
      maxWidth: 240,
      contentInsets: NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10),
      autoDismissDuration: 3,
      tapOutsideToDismiss: false,
      passesThroughOutsideTouches: true,
      keyboardAvoidance: .none
    )
  }

  /// Popover preset: wider surface, manual dismiss, light card style.
  public static func popoverDefault(placement: FKCalloutPlacement = .automatic) -> FKCalloutConfiguration {
    FKCalloutConfiguration(
      kind: .popover,
      placement: placement,
      appearance: FKCalloutAppearance(
        style: .light,
        cornerRadius: 12,
        beakWidth: 16,
        beakHeight: 8,
        showsShadow: true,
        shadowOpacity: 0.16,
        shadowRadius: 16,
        shadowOffset: CGSize(width: 0, height: 8),
        borderColor: .separator,
        borderWidth: 0.5
      ),
      anchorSpacing: 10,
      maxWidth: 320,
      contentInsets: NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16),
      autoDismissDuration: nil,
      tapOutsideToDismiss: true,
      passesThroughOutsideTouches: true
    )
  }

  /// Menu/select preset: aligns to anchor leading edge and matches anchor width when possible.
  public static func menuDefault(placement: FKCalloutPlacement = .bottomLeading) -> FKCalloutConfiguration {
    var config = popoverDefault(placement: placement)
    config.anchorAlignment = .leading
    config.matchesAnchorWidth = true
    config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    return config
  }
}
