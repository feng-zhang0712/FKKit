import UIKit

/// Applies ``FKCellUnreadPresentation`` to feed row chrome.
@MainActor
enum FKCellUnreadApplicator {
  static func apply(
    presentation: FKCellUnreadPresentation,
    to host: FKCellChromeHost,
    titleLabel: UILabel,
    appearance: FKCellAppearanceConfiguration
  ) {
    if presentation.isUnread && presentation.usesBoldTitle {
      titleLabel.font = .preferredFont(forTextStyle: .body).withWeight(.semibold)
    } else {
      titleLabel.font = .preferredFont(forTextStyle: .body)
    }

    if let tint = presentation.backgroundTint, presentation.isUnread {
      host.contentView.backgroundColor = tint
    }
  }

  static func configureBadge(
    on view: UIView,
    presentation: FKCellUnreadPresentation,
    badgeConfiguration: FKBadgeConfiguration = FKBadgeConfiguration()
  ) {
    view.fk_badge.configuration = badgeConfiguration
    if presentation.isUnread && presentation.showsBadge && presentation.badgeCount > 0 {
      view.fk_showBadgeCount(presentation.badgeCount)
    } else if presentation.isUnread && presentation.showsBadge && presentation.badgeCount == 0 {
      view.fk_showBadgeDot()
    } else {
      view.fk_clearBadge()
    }
  }
}

private extension UIFont {
  func withWeight(_ weight: UIFont.Weight) -> UIFont {
    let descriptor = fontDescriptor.addingAttributes([
      .traits: [UIFontDescriptor.TraitKey.weight: weight],
    ])
    return UIFont(descriptor: descriptor, size: pointSize)
  }
}
