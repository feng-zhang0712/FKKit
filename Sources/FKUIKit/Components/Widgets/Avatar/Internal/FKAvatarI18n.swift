import UIKit

enum FKAvatarI18n {
  static var defaultAvatarLabel: String {
    FKUIKitI18n.string("fkuikit.avatar.default_label")
  }

  static func avatarLabel(for displayName: String) -> String {
    FKUIKitI18n.format("fkuikit.avatar.named_label", displayName)
  }

  static var loadingAnnouncement: String {
    FKUIKitI18n.string("fkuikit.avatar.loading")
  }

  static var loadFailedAnnouncement: String {
    FKUIKitI18n.string("fkuikit.avatar.load_failed")
  }

  static var retryHint: String {
    FKUIKitI18n.string("fkuikit.avatar.retry_hint")
  }

  static func overflowMembers(count: Int) -> String {
    FKUIKitI18n.format("fkuikit.avatar.group.overflow", count)
  }

  static var verifiedBadgeHint: String {
    FKUIKitI18n.string("fkuikit.avatar.verified")
  }

  static func presenceAccessibilityLabel(for state: FKPresenceState) -> String {
    switch state {
    case .online:
      FKUIKitI18n.string("fkuikit.avatar.presence.online")
    case .offline:
      FKUIKitI18n.string("fkuikit.avatar.presence.offline")
    case .busy:
      FKUIKitI18n.string("fkuikit.avatar.presence.busy")
    case .away:
      FKUIKitI18n.string("fkuikit.avatar.presence.away")
    case .custom(let custom):
      custom.accessibilityLabel
    }
  }
}
