import CoreGraphics

/// Per-segment vertical spacing overrides for the main empty-state stack.
///
/// Each property maps to `UIStackView.setCustomSpacing(_:after:)` after the corresponding block.
/// `nil` falls back to the density-scaled ``FKEmptyStateLayoutConfiguration/verticalSpacing`` value.
///
/// Explicit segment values are **not** scaled by ``FKEmptyStateLayoutConfiguration/density``;
/// only the fallback spacing is.
public struct FKEmptyStateSpacingConfiguration: Equatable, Sendable {
  /// Spacing after the illustration block (image, custom accessory, or horizontal row) and before title.
  public var afterImage: CGFloat?
  /// Spacing after the title label and before the description (or the next block when description is hidden).
  public var afterTitle: CGFloat?
  /// Spacing after the description label and before the actions slot or button stack.
  public var afterDescription: CGFloat?
  /// Spacing after the actions slot container and before the button stack.
  public var afterActionsSlot: CGFloat?

  public init(
    afterImage: CGFloat? = nil,
    afterTitle: CGFloat? = nil,
    afterDescription: CGFloat? = nil,
    afterActionsSlot: CGFloat? = nil
  ) {
    self.afterImage = afterImage.map { max(0, $0) }
    self.afterTitle = afterTitle.map { max(0, $0) }
    self.afterDescription = afterDescription.map { max(0, $0) }
    self.afterActionsSlot = afterActionsSlot.map { max(0, $0) }
  }
}
