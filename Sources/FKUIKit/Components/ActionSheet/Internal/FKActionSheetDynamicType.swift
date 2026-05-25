import UIKit

enum FKActionSheetDynamicType {
  static func scaledFont(_ font: UIFont, textStyle: UIFont.TextStyle, maximumPointSize: CGFloat? = nil) -> UIFont {
    let metrics = UIFontMetrics(forTextStyle: textStyle)
    if let maximumPointSize {
      return metrics.scaledFont(for: font, maximumPointSize: maximumPointSize)
    }
    return metrics.scaledFont(for: font)
  }
}

extension FKActionSheetAppearance {
  func resolvedHeaderTitleFont() -> UIFont {
    FKActionSheetDynamicType.scaledFont(headerTitleFont, textStyle: .footnote, maximumPointSize: 22)
  }

  func resolvedHeaderMessageFont() -> UIFont {
    FKActionSheetDynamicType.scaledFont(headerMessageFont, textStyle: .footnote, maximumPointSize: 22)
  }

  func resolvedActionTitleFont(isCancel: Bool) -> UIFont {
    let base = isCancel ? cancelTitleFont : actionTitleFont
    return FKActionSheetDynamicType.scaledFont(base, textStyle: .title3, maximumPointSize: 34)
  }

  func resolvedActionSubtitleFont() -> UIFont {
    FKActionSheetDynamicType.scaledFont(actionSubtitleFont, textStyle: .footnote, maximumPointSize: 24)
  }

  func resolvedSectionTitleFont() -> UIFont {
    FKActionSheetDynamicType.scaledFont(sectionTitleFont, textStyle: .footnote, maximumPointSize: 20)
  }
}
