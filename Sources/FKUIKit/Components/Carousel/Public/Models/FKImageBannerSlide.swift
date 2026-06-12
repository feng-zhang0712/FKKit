import Foundation

/// Policy for opening slide link URLs.
public enum FKImageBannerLinkOpenPolicy: Equatable, Sendable {
  /// Open in an in-app browser when the host provides one.
  case inAppSafari
  /// Open with `UIApplication.shared.open`.
  case openSystem
  /// Delegate/callback only; no automatic open.
  case callbackOnly
}

/// Per-slide overlay style override.
public struct FKImageBannerOverlayStyle: Equatable, Sendable {
  /// Optional CTA title; `nil` hides the button.
  public var ctaTitle: String?

  /// Overlay text visibility for this slide.
  public var visibility: FKImageBannerOverlayVisibility

  /// Creates a per-slide overlay style.
  public init(
    ctaTitle: String? = nil,
    visibility: FKImageBannerOverlayVisibility = .always
  ) {
    self.ctaTitle = ctaTitle
    self.visibility = visibility
  }
}

/// Overlay visibility policy.
public enum FKImageBannerOverlayVisibility: Equatable, Sendable {
  case always
  case accessibilityOnly
  case never
}

/// Marketing / feed hero slide model.
public struct FKImageBannerSlide: Equatable, @unchecked Sendable {
  /// Stable identifier across reloads.
  public let id: String

  /// Image source for the slide background.
  public let imageSource: FKImageBannerImageSource

  /// Optional headline.
  public let title: String?

  /// Optional subtitle.
  public let subtitle: String?

  /// Optional VoiceOver label; combined with page position.
  public let accessibilityLabel: String?

  /// Optional deep link opened when the slide is tapped.
  public let linkURL: URL?

  /// How ``linkURL`` should be opened.
  public let linkOpenPolicy: FKImageBannerLinkOpenPolicy

  /// Whether the slide accepts tap selection.
  public let isInteractive: Bool

  /// Optional per-slide overlay override.
  public let overlayStyle: FKImageBannerOverlayStyle?

  /// Creates an image banner slide.
  public init(
    id: String,
    imageSource: FKImageBannerImageSource,
    title: String? = nil,
    subtitle: String? = nil,
    accessibilityLabel: String? = nil,
    linkURL: URL? = nil,
    linkOpenPolicy: FKImageBannerLinkOpenPolicy = .callbackOnly,
    isInteractive: Bool = true,
    overlayStyle: FKImageBannerOverlayStyle? = nil
  ) {
    self.id = id
    self.imageSource = imageSource
    self.title = title
    self.subtitle = subtitle
    self.accessibilityLabel = accessibilityLabel
    self.linkURL = linkURL
    self.linkOpenPolicy = linkOpenPolicy
    self.isInteractive = isInteractive
    self.overlayStyle = overlayStyle
  }
}

extension FKImageBannerSlide {
  /// Maps slide identity to a carousel item.
  public var carouselItem: FKCarouselItem {
    FKCarouselItem(
      id: id,
      accessibilityLabel: accessibilityLabel ?? title,
      isInteractive: isInteractive
    )
  }
}
