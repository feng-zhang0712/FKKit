import Foundation

/// Resolves localized strings from the FKUIKit resource bundle via ``FKI18nManager``.
public enum FKVideoPlayerStrings {
  public static var play: String { FKUIKitI18n.string("fkuikit.video.play") }
  public static var pause: String { FKUIKitI18n.string("fkuikit.video.pause") }
  public static var loading: String { FKUIKitI18n.string("fkuikit.video.loading") }
  public static var retry: String { FKUIKitI18n.string("fkuikit.video.retry") }
  public static var fullscreen: String { FKUIKitI18n.string("fkuikit.video.fullscreen") }
  public static var settings: String { FKUIKitI18n.string("fkuikit.video.settings") }
  public static var live: String { FKUIKitI18n.string("fkuikit.video.live") }
  public static var close: String { FKUIKitI18n.string("fkuikit.video.close") }
  public static var progress: String { FKUIKitI18n.string("fkuikit.video.progress") }
  public static var screenCaptureBlocked: String { FKUIKitI18n.string("fkuikit.video.screen_capture") }
}
