import UIKit

/// Geometry for ``FKRadioGroup``.
public struct FKRadioGroupLayoutConfiguration: Sendable, Equatable {
  public var style: FKRadioGroupLayoutStyle
  public var size: FKSelectionControlSize
  public var indicatorEdge: FKSelectionControlIndicatorEdge
  public var rowMinHeight: CGFloat
  public var separatorInset: NSDirectionalEdgeInsets
  public var cornerRadius: CGFloat
  public var axisSpacing: CGFloat
  public var headerFooterSpacing: CGFloat
  public var rowContentInsets: NSDirectionalEdgeInsets
  public var indicatorTitleSpacing: CGFloat
  public var titleSubtitleSpacing: CGFloat
  public var imageTitleSpacing: CGFloat
  /// When non-`nil`, the group scrolls vertically after this many visible options.
  public var maximumVisibleOptions: Int?

  public init(
    style: FKRadioGroupLayoutStyle = .insetGrouped,
    size: FKSelectionControlSize = .medium,
    indicatorEdge: FKSelectionControlIndicatorEdge = .leading,
    rowMinHeight: CGFloat = 44,
    separatorInset: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 16),
    cornerRadius: CGFloat = 12,
    axisSpacing: CGFloat = 0,
    headerFooterSpacing: CGFloat = 8,
    rowContentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16),
    indicatorTitleSpacing: CGFloat = 12,
    titleSubtitleSpacing: CGFloat = 4,
    imageTitleSpacing: CGFloat = 10,
    maximumVisibleOptions: Int? = nil
  ) {
    self.style = style
    self.size = size
    self.indicatorEdge = indicatorEdge
    self.rowMinHeight = max(0, rowMinHeight)
    self.separatorInset = separatorInset
    self.cornerRadius = max(0, cornerRadius)
    self.axisSpacing = max(0, axisSpacing)
    self.headerFooterSpacing = max(0, headerFooterSpacing)
    self.rowContentInsets = rowContentInsets
    self.indicatorTitleSpacing = max(0, indicatorTitleSpacing)
    self.titleSubtitleSpacing = max(0, titleSubtitleSpacing)
    self.imageTitleSpacing = max(0, imageTitleSpacing)
    self.maximumVisibleOptions = maximumVisibleOptions.map { max(1, $0) }
  }
}
