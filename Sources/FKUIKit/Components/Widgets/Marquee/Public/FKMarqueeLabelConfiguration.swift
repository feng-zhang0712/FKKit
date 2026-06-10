import UIKit

/// Horizontal scroll direction for ``FKMarqueeLabel``.
public enum FKMarqueeLabelDirection: Sendable, Equatable {
  /// Content moves toward the leading edge (classic ticker).
  case left
  /// Content moves toward the trailing edge.
  case right
}

/// Alignment for short text that does not require scrolling.
public enum FKMarqueeLabelAlignment: Sendable, Equatable {
  /// Align to the leading edge in the current layout direction.
  case leading
  /// Center within the available width.
  case center
}

/// Layout parameters for ``FKMarqueeLabel``.
public struct FKMarqueeLabelLayoutConfiguration: Sendable, Equatable {
  public var alignment: FKMarqueeLabelAlignment

  public init(alignment: FKMarqueeLabelAlignment = .leading) {
    self.alignment = alignment
  }
}

/// Visual styling for ``FKMarqueeLabel``.
public struct FKMarqueeLabelAppearanceConfiguration: @unchecked Sendable, Equatable {
  /// Dynamic Type text style used when ``fontOverride`` is `nil`.
  public var textStyle: UIFont.TextStyle
  /// Optional fixed font; when set, ``textStyle`` is ignored.
  public var fontOverride: UIFont?
  public var textColor: UIColor

  public init(
    textStyle: UIFont.TextStyle = .subheadline,
    fontOverride: UIFont? = nil,
    textColor: UIColor = .label
  ) {
    self.textStyle = textStyle
    self.fontOverride = fontOverride
    self.textColor = textColor
  }
}

extension FKMarqueeLabelAppearanceConfiguration {
  public static func == (lhs: FKMarqueeLabelAppearanceConfiguration, rhs: FKMarqueeLabelAppearanceConfiguration) -> Bool {
    lhs.textStyle == rhs.textStyle
      && lhs.fontOverride == rhs.fontOverride
      && lhs.textColor.isEqual(rhs.textColor)
  }
}

/// Animation and scrolling parameters for ``FKMarqueeLabel``.
public struct FKMarqueeLabelAnimationConfiguration: Sendable, Equatable {
  /// Scroll speed in points per second.
  public var speed: CGFloat
  /// Horizontal gap between the end of one loop copy and the start of the next.
  public var loopGap: CGFloat
  /// Pause before scrolling begins after layout (seconds).
  public var delay: TimeInterval
  public var direction: FKMarqueeLabelDirection
  /// When `true`, ``direction`` mirrors under right-to-left layout.
  public var mirrorsDirectionInRTL: Bool
  /// Width of leading/trailing fade masks; `0` disables fading.
  public var fadeWidth: CGFloat
  /// When `true`, scrolling stops while Reduce Motion is enabled.
  public var respectsReducedMotion: Bool

  public init(
    speed: CGFloat = 36,
    loopGap: CGFloat = 32,
    delay: TimeInterval = 1,
    direction: FKMarqueeLabelDirection = .left,
    mirrorsDirectionInRTL: Bool = true,
    fadeWidth: CGFloat = 16,
    respectsReducedMotion: Bool = true
  ) {
    self.speed = speed
    self.loopGap = loopGap
    self.delay = delay
    self.direction = direction
    self.mirrorsDirectionInRTL = mirrorsDirectionInRTL
    self.fadeWidth = fadeWidth
    self.respectsReducedMotion = respectsReducedMotion
  }
}

/// Interaction settings for ``FKMarqueeLabel``.
public struct FKMarqueeLabelInteractionConfiguration: Sendable, Equatable {
  /// When `true`, a pan gesture pauses scrolling while the finger is down.
  public var pausesOnPan: Bool

  public init(pausesOnPan: Bool = true) {
    self.pausesOnPan = pausesOnPan
  }
}

/// Accessibility settings for ``FKMarqueeLabel``.
public struct FKMarqueeLabelAccessibilityConfiguration: Sendable, Equatable {
  /// Overrides the default accessibility label (`text`).
  public var customLabel: String?
  /// When `true`, applies ``UIAccessibility/Trait/updatesFrequently`` while actively scrolling.
  public var usesUpdatesFrequentlyTraitWhenScrolling: Bool

  public init(
    customLabel: String? = nil,
    usesUpdatesFrequentlyTraitWhenScrolling: Bool = false
  ) {
    self.customLabel = customLabel
    self.usesUpdatesFrequentlyTraitWhenScrolling = usesUpdatesFrequentlyTraitWhenScrolling
  }
}

/// Layered configuration for ``FKMarqueeLabel``.
public struct FKMarqueeLabelConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKMarqueeLabelLayoutConfiguration
  public var appearance: FKMarqueeLabelAppearanceConfiguration
  public var animation: FKMarqueeLabelAnimationConfiguration
  public var interaction: FKMarqueeLabelInteractionConfiguration
  public var accessibility: FKMarqueeLabelAccessibilityConfiguration

  public init(
    layout: FKMarqueeLabelLayoutConfiguration = .init(),
    appearance: FKMarqueeLabelAppearanceConfiguration = .init(),
    animation: FKMarqueeLabelAnimationConfiguration = .init(),
    interaction: FKMarqueeLabelInteractionConfiguration = .init(),
    accessibility: FKMarqueeLabelAccessibilityConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.animation = animation
    self.interaction = interaction
    self.accessibility = accessibility
  }
}

/// Thread-safe global defaults for ``FKMarqueeLabel``.
public enum FKMarqueeLabelDefaults {
  @MainActor public static var configuration = FKMarqueeLabelConfiguration()
}
