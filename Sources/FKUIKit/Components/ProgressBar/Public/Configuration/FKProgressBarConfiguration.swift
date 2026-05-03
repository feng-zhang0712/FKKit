import UIKit

/// Appearance, motion, accessibility hints, and optional label behavior for ``FKProgressBar``.
///
/// - Note: Marked `@unchecked Sendable` because `UIColor`, `UIFont`, and `NumberFormatter` are not `Sendable`;
///   treat instances as main-thread configuration snapshots copied into the view.
public struct FKProgressBarConfiguration: @unchecked Sendable {
  // MARK: Variant & layout

  public var variant: FKProgressBarVariant
  public var axis: FKProgressBarAxis

  /// Linear track thickness (height for horizontal, width for vertical).
  public var trackThickness: CGFloat
  /// Corner radius for the linear track; `nil` uses half of `trackThickness` (capsule).
  public var trackCornerRadius: CGFloat?

  /// Ring stroke width (``FKProgressBarVariant/ring``).
  public var ringLineWidth: CGFloat
  /// Total diameter of the ring including stroke; `nil` uses intrinsic default (36 pt).
  public var ringDiameter: CGFloat?

  /// Insets applied inside the view bounds before laying out track / ring / label.
  public var contentInsets: UIEdgeInsets

  // MARK: Colors & borders

  public var trackColor: UIColor
  public var progressColor: UIColor
  /// Secondary fill (e.g. buffered stream) drawn behind progress when ``showsBuffer`` is `true`.
  public var bufferColor: UIColor

  public var trackBorderWidth: CGFloat
  public var trackBorderColor: UIColor
  public var progressBorderWidth: CGFloat
  public var progressBorderColor: UIColor

  public var fillStyle: FKProgressBarFillStyle
  public var progressGradientEndColor: UIColor

  // MARK: Linear specifics

  public var linearCapStyle: FKProgressBarLinearCapStyle
  /// When `> 1`, draws a segmented track (visual chunks); `0` or `1` is a continuous bar.
  public var segmentCount: Int
  /// Gap between segments as a fraction of segment width (clamped).
  public var segmentGapFraction: CGFloat

  // MARK: Buffer & motion

  public var showsBuffer: Bool
  public var animationDuration: TimeInterval
  public var timing: FKProgressBarTiming
  /// When `true`, uses `UIView.animate` spring for determinate changes instead of `CAMediaTimingFunction`.
  public var prefersSpringAnimation: Bool
  public var springDampingRatio: CGFloat
  public var springVelocity: CGFloat

  public var indeterminateStyle: FKProgressBarIndeterminateStyle
  /// One full marquee cycle duration (linear) or pulse period (breathing).
  public var indeterminatePeriod: TimeInterval

  public var respectsReducedMotion: Bool
  public var completionHaptic: FKProgressBarCompletionHaptic

  // MARK: Label

  public var labelPlacement: FKProgressBarLabelPlacement
  public var labelFormat: FKProgressBarLabelFormat
  public var labelFractionDigits: Int
  public var labelFont: UIFont
  public var labelColor: UIColor
  public var labelPadding: CGFloat
  /// When `true`, the label ignores `labelColor` and uses `UIColor.label` (adapts in Dark Mode).
  public var labelUsesSemanticLabelColor: Bool

  // MARK: Logical range (display / a11y)

  /// Logical minimum corresponding to progress `0`.
  public var logicalMinimum: Double
  /// Logical maximum corresponding to progress `1`.
  public var logicalMaximum: Double
  /// Optional prefix/suffix around formatted label text (e.g. `" "` + `" MB"`).
  public var labelPrefix: String
  public var labelSuffix: String

  // MARK: Accessibility

  /// When non-empty, overrides the default `accessibilityLabel` for the control.
  public var accessibilityCustomLabel: String?
  /// When non-empty, appended as additional hint after system hints.
  public var accessibilityCustomHint: String?
  /// When `true`, exposes `UIAccessibilityTraits.updatesFrequently` while indeterminate or animating.
  public var accessibilityTreatAsFrequentUpdates: Bool

  // MARK: Number formatting

  /// Used for `.logicalRangeValue` label format and optional custom grouping.
  public var numberFormatter: NumberFormatter?

  public init(
    variant: FKProgressBarVariant = .linear,
    axis: FKProgressBarAxis = .horizontal,
    trackThickness: CGFloat = 4,
    trackCornerRadius: CGFloat? = nil,
    ringLineWidth: CGFloat = 4,
    ringDiameter: CGFloat? = nil,
    contentInsets: UIEdgeInsets = .zero,
    trackColor: UIColor = .tertiarySystemFill,
    progressColor: UIColor = .systemBlue,
    bufferColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.35),
    trackBorderWidth: CGFloat = 0,
    trackBorderColor: UIColor = .clear,
    progressBorderWidth: CGFloat = 0,
    progressBorderColor: UIColor = .clear,
    fillStyle: FKProgressBarFillStyle = .solid,
    progressGradientEndColor: UIColor = .systemTeal,
    linearCapStyle: FKProgressBarLinearCapStyle = .round,
    segmentCount: Int = 0,
    segmentGapFraction: CGFloat = 0.08,
    showsBuffer: Bool = false,
    animationDuration: TimeInterval = 0.25,
    timing: FKProgressBarTiming = .default,
    prefersSpringAnimation: Bool = false,
    springDampingRatio: CGFloat = 0.82,
    springVelocity: CGFloat = 0.35,
    indeterminateStyle: FKProgressBarIndeterminateStyle = .marquee,
    indeterminatePeriod: TimeInterval = 1.35,
    respectsReducedMotion: Bool = true,
    completionHaptic: FKProgressBarCompletionHaptic = .none,
    labelPlacement: FKProgressBarLabelPlacement = .none,
    labelFormat: FKProgressBarLabelFormat = .percentInteger,
    labelFractionDigits: Int = 1,
    labelFont: UIFont = .preferredFont(forTextStyle: .footnote),
    labelColor: UIColor = .secondaryLabel,
    labelPadding: CGFloat = 4,
    labelUsesSemanticLabelColor: Bool = false,
    logicalMinimum: Double = 0,
    logicalMaximum: Double = 1,
    labelPrefix: String = "",
    labelSuffix: String = "",
    accessibilityCustomLabel: String? = nil,
    accessibilityCustomHint: String? = nil,
    accessibilityTreatAsFrequentUpdates: Bool = true,
    numberFormatter: NumberFormatter? = nil
  ) {
    self.variant = variant
    self.axis = axis
    self.trackThickness = max(0.5, trackThickness)
    self.trackCornerRadius = trackCornerRadius
    self.ringLineWidth = max(0.5, ringLineWidth)
    self.ringDiameter = ringDiameter.map { max(8, $0) }
    self.contentInsets = contentInsets
    self.trackColor = trackColor
    self.progressColor = progressColor
    self.bufferColor = bufferColor
    self.trackBorderWidth = max(0, trackBorderWidth)
    self.trackBorderColor = trackBorderColor
    self.progressBorderWidth = max(0, progressBorderWidth)
    self.progressBorderColor = progressBorderColor
    self.fillStyle = fillStyle
    self.progressGradientEndColor = progressGradientEndColor
    self.linearCapStyle = linearCapStyle
    self.segmentCount = max(0, segmentCount)
    self.segmentGapFraction = min(max(0, segmentGapFraction), 0.45)
    self.showsBuffer = showsBuffer
    self.animationDuration = max(0, animationDuration)
    self.timing = timing
    self.prefersSpringAnimation = prefersSpringAnimation
    self.springDampingRatio = min(max(0.01, springDampingRatio), 1.2)
    self.springVelocity = springVelocity
    self.indeterminateStyle = indeterminateStyle
    self.indeterminatePeriod = max(0.2, indeterminatePeriod)
    self.respectsReducedMotion = respectsReducedMotion
    self.completionHaptic = completionHaptic
    self.labelPlacement = labelPlacement
    self.labelFormat = labelFormat
    self.labelFractionDigits = max(0, min(6, labelFractionDigits))
    self.labelFont = labelFont
    self.labelColor = labelColor
    self.labelPadding = max(0, labelPadding)
    self.labelUsesSemanticLabelColor = labelUsesSemanticLabelColor
    self.logicalMinimum = logicalMinimum
    self.logicalMaximum = logicalMaximum
    self.labelPrefix = labelPrefix
    self.labelSuffix = labelSuffix
    self.accessibilityCustomLabel = accessibilityCustomLabel
    self.accessibilityCustomHint = accessibilityCustomHint
    self.accessibilityTreatAsFrequentUpdates = accessibilityTreatAsFrequentUpdates
    self.numberFormatter = numberFormatter
  }
}

// MARK: - Global defaults

/// Namespace for shared defaults applied to new ``FKProgressBar`` instances.
@MainActor
public enum FKProgressBarDefaults {
  /// Baseline copied at initialization until the host replaces ``FKProgressBar/configuration``.
  public static var configuration = FKProgressBarConfiguration()
}
