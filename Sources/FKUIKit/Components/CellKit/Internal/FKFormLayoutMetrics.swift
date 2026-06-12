import UIKit

/// Layout constants for form field chrome (§11.1, §3.6.2).
enum FKFormLayoutMetrics {
  static let underlineNormalThickness: CGFloat = 1
  static let underlineFocusedThickness: CGFloat = 2
  static let cardCornerRadius: CGFloat = 10
  static let cardContentInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
  static let inlineLabelWidthRatio: CGFloat = 0.32
  static let minimumFieldRowHeight: CGFloat = 44
  static let labelFieldSpacing: CGFloat = 6
  static let messageTopSpacing: CGFloat = 4
  static let cellHorizontalInset: CGFloat = 16
  static let cellVerticalInset: CGFloat = 8
  static let prefixTextSpacing: CGFloat = 6
  static let phoneCountryWidthRatio: CGFloat = 0.36
  static let phoneSplitDividerThickness: CGFloat = 1
  static let phoneSplitDividerSpacing: CGFloat = 8
}
