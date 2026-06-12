import UIKit

/// Shared layout constants for CellKit rows (see design §11.1).
enum FKCellLayoutMetrics {
  static let minimumRowHeight: CGFloat = 44
  static let doubleLineRowHeight: CGFloat = 56
  static let horizontalContentInset: CGFloat = 16
  static let groupedHorizontalMargin: CGFloat = 20
  static let groupedCornerRadius: CGFloat = 10
  static let iconColumnWidth: CGFloat = 32
  static let infoIconSide: CGFloat = 60
  static let checkmarkColumnWidth: CGFloat = 28
  static let iconColumnSpacing: CGFloat = 12
  static let trailingAccessorySpacing: CGFloat = 6
  /// Width of the disclosure chevron slot.
  static let chevronWidth: CGFloat = 13
  /// Height of the disclosure chevron slot and symbol point size.
  static let chevronHeight: CGFloat = 17
  static let titleSubtitleSpacing: CGFloat = 2
  static let sectionHeaderTopInset: CGFloat = 24
  static let sectionHeaderBottomInset: CGFloat = 8
  static let sectionFooterTopInset: CGFloat = 8
  static let sectionFooterBottomInset: CGFloat = 24
  static let heroIconSize: CGFloat = 64
  static let feedAvatarSize: CGFloat = 56
  static let compactAvatarSize: CGFloat = 40
  static let thumbnailSize: CGFloat = 56
  static let audioCoverSize: CGFloat = 48
  static let articleThumbnailWidth: CGFloat = 80
  static let articleThumbnailHeight: CGFloat = 56
  static let productImageSize: CGFloat = 72
  static let metaColumnMinWidth: CGFloat = 56
  static let unreadDotSize: CGFloat = 8
}
