import UIKit

/// Geometry for rating items and optional caption placement.
public struct FKRatingLayoutConfiguration: Sendable, Equatable {
  /// Number of icon slots rendered left-to-right (or right-to-left in RTL).
  public var itemCount: Int
  /// Width and height of each icon slot in points.
  public var itemSize: CGSize
  /// Horizontal spacing between icon slots.
  public var itemSpacing: CGFloat
  /// Insets around the icon row inside the control bounds.
  public var contentInsets: NSDirectionalEdgeInsets
  /// Placement of the optional value caption.
  public var labelPlacement: FKRatingLabelPlacement
  /// Spacing between the icon row and caption when a label is shown.
  public var labelSpacing: CGFloat

  public init(
    itemCount: Int = 5,
    itemSize: CGSize = CGSize(width: 28, height: 28),
    itemSpacing: CGFloat = 6,
    contentInsets: NSDirectionalEdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0),
    labelPlacement: FKRatingLabelPlacement = .none,
    labelSpacing: CGFloat = 6
  ) {
    self.itemCount = max(1, itemCount)
    self.itemSize = CGSize(width: max(4, itemSize.width), height: max(4, itemSize.height))
    self.itemSpacing = max(0, itemSpacing)
    self.contentInsets = contentInsets
    self.labelPlacement = labelPlacement
    self.labelSpacing = max(0, labelSpacing)
  }
}
