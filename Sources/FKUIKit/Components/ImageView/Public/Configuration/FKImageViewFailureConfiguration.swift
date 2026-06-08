import UIKit

/// Failure UI and retry behavior for ``FKImageView``.
public struct FKImageViewFailureConfiguration: @unchecked Sendable {
  /// When `true`, failure UI exposes retry (button or tap-on-image).
  public var isRetryEnabled: Bool
  /// SF Symbol name or custom image for the failure glyph.
  public var iconSymbolName: String
  /// Optional custom failure icon; when non-`nil`, takes precedence over ``iconSymbolName``.
  public var iconImage: UIImage?
  /// Optional message below the icon; `nil` uses reason-specific defaults.
  public var message: String?
  /// Retry button title; `nil` means tap anywhere on the failure overlay.
  public var retryButtonTitle: String?
  /// When `true`, retry uses ``FKImageLoadCachePolicy/reloadIgnoringCache`` (memory skip, disk still written).
  public var retryIgnoresMemoryCache: Bool
  /// When `false`, failures update state only and keep the placeholder visible (no overlay subtree).
  public var showsFailureOverlay: Bool

  /// Creates failure defaults.
  public init(
    isRetryEnabled: Bool = true,
    iconSymbolName: String = "photo.badge.exclamationmark",
    iconImage: UIImage? = nil,
    message: String? = nil,
    retryButtonTitle: String? = nil,
    retryIgnoresMemoryCache: Bool = false,
    showsFailureOverlay: Bool = true
  ) {
    self.isRetryEnabled = isRetryEnabled
    self.iconSymbolName = iconSymbolName
    self.iconImage = iconImage
    self.message = message
    self.retryButtonTitle = retryButtonTitle
    self.retryIgnoresMemoryCache = retryIgnoresMemoryCache
    self.showsFailureOverlay = showsFailureOverlay
  }

  /// Resolves the message shown for `reason`, preferring explicit ``message``.
  public func resolvedMessage(for reason: FKImageViewFailureReason) -> String? {
    if let message, !message.isEmpty { return message }
    switch reason {
    case .offline:
      return FKImageViewI18n.offlineMessage
    case .network:
      return FKImageViewI18n.networkMessage
    case .decode:
      return FKImageViewI18n.decodeMessage
    case .cancelled:
      return nil
    case .custom(let message):
      return message
    }
  }

  /// Resolved retry title for buttons and accessibility hints.
  public var resolvedRetryTitle: String {
    if let retryButtonTitle, !retryButtonTitle.isEmpty { return retryButtonTitle }
    return FKImageViewI18n.retryTitle
  }
}
