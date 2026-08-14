import UIKit

/// Geometry for ``FKRadioButton``.
public struct FKRadioButtonLayoutConfiguration: Sendable, Equatable {
  public var size: FKSelectionControlSize
  public var labelPlacement: FKSelectionControlLabelPlacement
  public var indicatorEdge: FKSelectionControlIndicatorEdge
  public var indicatorTitleSpacing: CGFloat
  public var titleSubtitleSpacing: CGFloat
  public var imageTitleSpacing: CGFloat
  public var contentInsets: NSDirectionalEdgeInsets
  public var expandsHitTargetToMinimum: Bool
  public var titleNumberOfLines: Int
  public var subtitleNumberOfLines: Int
  public var rowMinHeight: CGFloat

  public init(
    size: FKSelectionControlSize = .medium,
    labelPlacement: FKSelectionControlLabelPlacement = .trailing,
    indicatorEdge: FKSelectionControlIndicatorEdge = .leading,
    indicatorTitleSpacing: CGFloat = 12,
    titleSubtitleSpacing: CGFloat = 4,
    imageTitleSpacing: CGFloat = 10,
    contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16),
    expandsHitTargetToMinimum: Bool = true,
    titleNumberOfLines: Int = 0,
    subtitleNumberOfLines: Int = 2,
    rowMinHeight: CGFloat = 44
  ) {
    self.size = size
    self.labelPlacement = labelPlacement
    self.indicatorEdge = indicatorEdge
    self.indicatorTitleSpacing = max(0, indicatorTitleSpacing)
    self.titleSubtitleSpacing = max(0, titleSubtitleSpacing)
    self.imageTitleSpacing = max(0, imageTitleSpacing)
    self.contentInsets = contentInsets
    self.expandsHitTargetToMinimum = expandsHitTargetToMinimum
    self.titleNumberOfLines = max(0, titleNumberOfLines)
    self.subtitleNumberOfLines = max(0, subtitleNumberOfLines)
    self.rowMinHeight = max(0, rowMinHeight)
  }
}
