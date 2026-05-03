import UIKit

/// ``FKProgressBar`` as control vs indicator, touch target, haptics, and disabled / highlight opacity.
public struct FKProgressBarInteractionConfiguration: Sendable {
  /// ``FKProgressBarInteractionMode/button`` enables ``UIControl`` target/action semantics.
  public var interactionMode: FKProgressBarInteractionMode
  /// Multiplier applied to track + fill layer opacity while highlighted in button mode (typically `0.88…1`).
  public var buttonHighlightedContentAlphaMultiplier: CGFloat
  /// Opacity for the whole drawing when ``UIControl/isEnabled`` is `false` in button mode.
  public var disabledContentAlpha: CGFloat
  /// When set in button mode, ``FKProgressBar`` expands its hit test to at least this size (centered), per HIG minimum touch targets.
  public var minimumTouchTargetSize: CGSize?
  public var touchHaptic: FKProgressBarTouchHaptic

  public init(
    interactionMode: FKProgressBarInteractionMode = .indicator,
    buttonHighlightedContentAlphaMultiplier: CGFloat = 0.9,
    disabledContentAlpha: CGFloat = 0.48,
    minimumTouchTargetSize: CGSize? = nil,
    touchHaptic: FKProgressBarTouchHaptic = .none
  ) {
    self.interactionMode = interactionMode
    self.buttonHighlightedContentAlphaMultiplier = min(max(0.2, buttonHighlightedContentAlphaMultiplier), 1)
    self.disabledContentAlpha = min(max(0.1, disabledContentAlpha), 1)
    self.minimumTouchTargetSize = minimumTouchTargetSize
    self.touchHaptic = touchHaptic
  }
}
