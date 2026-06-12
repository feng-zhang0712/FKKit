import UIKit

/// Layout hints and optional overrides for ``FKEmptyStateView``.
///
/// Properties marked optional fall back to ``FKEmptyStateLayoutContext`` presets when `nil`.
public struct FKEmptyStateLayoutConfiguration {
  /// Screen context for presets and layout decisions.
  public var context: FKEmptyStateLayoutContext
  /// Density preset used to derive spacing/layout defaults (does not override explicit values).
  public var density: FKEmptyStateDensity
  /// Stack direction for content blocks (vertical/horizontal). Loading phase always uses vertical layout.
  public var axis: FKEmptyStateAxis

  /// Fixed image dimensions when set; intrinsic sizing otherwise.
  public var imageSize: CGSize?
  /// Default vertical spacing between stack subviews; `nil` uses the context preset.
  ///
  /// Also used as the fallback when ``segmentSpacing`` properties are `nil`.
  /// This value **is** scaled by ``density`` (compact ×0.75, comfortable ×1.25).
  public var verticalSpacing: CGFloat?
  /// Per-segment spacing overrides; explicit values are not scaled by ``density``.
  public var segmentSpacing: FKEmptyStateSpacingConfiguration
  /// Padding around the content column; `nil` uses the context preset.
  public var contentInsets: UIEdgeInsets?
  /// Max width of the centered content column; `nil` uses the context preset.
  public var maxContentWidth: CGFloat?
  /// Vertical content alignment in the host view; `nil` uses the context preset.
  public var contentAlignment: FKEmptyStateContentAlignment?
  /// Additional Y offset for the content container (positive = lower, negative = higher).
  public var verticalOffset: CGFloat
  /// Overrides layout direction for RTL testing or forced direction UI. `nil` follows system.
  public var forcedLayoutDirection: UIUserInterfaceLayoutDirection?

  public init(
    context: FKEmptyStateLayoutContext = .section,
    density: FKEmptyStateDensity = .regular,
    axis: FKEmptyStateAxis = .vertical,
    imageSize: CGSize? = nil,
    verticalSpacing: CGFloat? = nil,
    segmentSpacing: FKEmptyStateSpacingConfiguration = FKEmptyStateSpacingConfiguration(),
    contentInsets: UIEdgeInsets? = nil,
    maxContentWidth: CGFloat? = nil,
    contentAlignment: FKEmptyStateContentAlignment? = nil,
    verticalOffset: CGFloat = 0,
    forcedLayoutDirection: UIUserInterfaceLayoutDirection? = nil
  ) {
    self.context = context
    self.density = density
    self.axis = axis
    self.imageSize = imageSize
    self.verticalSpacing = verticalSpacing.map { max(0, $0) }
    self.segmentSpacing = segmentSpacing
    self.contentInsets = contentInsets
    self.maxContentWidth = maxContentWidth.map { max(180, $0) }
    self.contentAlignment = contentAlignment
    self.verticalOffset = verticalOffset
    self.forcedLayoutDirection = forcedLayoutDirection
  }
}
