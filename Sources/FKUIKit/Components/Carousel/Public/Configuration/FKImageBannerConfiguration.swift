import UIKit

/// Image content mode for banner slides.
public enum FKImageBannerImageContentMode: Equatable, Sendable {
  case scaleAspectFill
  case scaleAspectFit
  case scaleToFill
}

/// Overlay expansion when Dynamic Type grows text.
public enum FKImageBannerOverlayExpansionPolicy: Equatable, Sendable {
  case fixedBannerHeight
  case growBanner
}

/// Failure handling for a single slide image load.
public enum FKImageBannerFailurePolicy: Equatable, Sendable {
  case hideSlide
  case showErrorPlaceholder
}

/// Gradient overlay configuration for text legibility.
public struct FKImageBannerGradientOverlay: Equatable, Sendable {
  /// Gradient colors from top to bottom.
  public var colors: [UIColor]

  /// Gradient stop locations (`0...1`).
  public var locations: [CGFloat]

  /// Creates gradient overlay settings.
  public init(
    colors: [UIColor] = [
      UIColor.black.withAlphaComponent(0),
      UIColor.black.withAlphaComponent(0.55),
    ],
    locations: [CGFloat] = [0.35, 1.0]
  ) {
    self.colors = colors
    self.locations = locations
  }
}

/// Card chrome for peek layouts.
public struct FKImageBannerCardStyle: Equatable, Sendable {
  /// Corner radius applied to each slide.
  public var cornerRadius: CGFloat

  /// Optional corner shadow style identifier resolved by the host.
  public var usesCornerShadow: Bool

  /// Creates card style settings.
  public init(cornerRadius: CGFloat = 12, usesCornerShadow: Bool = true) {
    self.cornerRadius = cornerRadius
    self.usesCornerShadow = usesCornerShadow
  }
}

/// Image-banner-specific configuration mapped to ``FKCarouselConfiguration``.
public struct FKImageBannerConfiguration: Equatable, Sendable {
  /// Underlying carousel configuration.
  public var carousel: FKCarouselConfiguration

  /// Image view content mode.
  public var imageContentMode: FKImageBannerImageContentMode

  /// Default overlay visibility.
  public var overlayVisibility: FKImageBannerOverlayVisibility

  /// Maximum title lines.
  public var maximumTitleLines: Int

  /// Maximum subtitle lines.
  public var maximumSubtitleLines: Int

  /// Default CTA title; per-slide override via ``FKImageBannerOverlayStyle``.
  public var defaultCTATitle: String?

  /// Whether CTA taps also open ``FKImageBannerSlide/linkURL``.
  public var ctaUsesLinkURL: Bool

  /// Gradient scrim over images.
  public var gradientOverlay: FKImageBannerGradientOverlay

  /// Card chrome for peek layouts.
  public var cardStyle: FKImageBannerCardStyle?

  /// Number of neighbor slides to prefetch after settle.
  public var prefetchRadius: Int

  /// Failure handling policy.
  public var failurePolicy: FKImageBannerFailurePolicy

  /// Overlay expansion under large content sizes.
  public var overlayExpansionPolicy: FKImageBannerOverlayExpansionPolicy

  /// Allowed URL schemes for automatic open (`http`, `https`, `tel` always allowed).
  public var allowedLinkSchemes: Set<String>

  /// Shows skeleton shimmer while loading remote images.
  public var showsSkeletonWhileLoading: Bool

  /// Creates image banner configuration.
  public init(
    carousel: FKCarouselConfiguration = .init(),
    imageContentMode: FKImageBannerImageContentMode = .scaleAspectFill,
    overlayVisibility: FKImageBannerOverlayVisibility = .always,
    maximumTitleLines: Int = 2,
    maximumSubtitleLines: Int = 1,
    defaultCTATitle: String? = nil,
    ctaUsesLinkURL: Bool = false,
    gradientOverlay: FKImageBannerGradientOverlay = .init(),
    cardStyle: FKImageBannerCardStyle? = nil,
    prefetchRadius: Int = 1,
    failurePolicy: FKImageBannerFailurePolicy = .showErrorPlaceholder,
    overlayExpansionPolicy: FKImageBannerOverlayExpansionPolicy = .fixedBannerHeight,
    allowedLinkSchemes: Set<String> = [],
    showsSkeletonWhileLoading: Bool = true
  ) {
    self.carousel = carousel
    self.imageContentMode = imageContentMode
    self.overlayVisibility = overlayVisibility
    self.maximumTitleLines = maximumTitleLines
    self.maximumSubtitleLines = maximumSubtitleLines
    self.defaultCTATitle = defaultCTATitle
    self.ctaUsesLinkURL = ctaUsesLinkURL
    self.gradientOverlay = gradientOverlay
    self.cardStyle = cardStyle
    self.prefetchRadius = prefetchRadius
    self.failurePolicy = failurePolicy
    self.overlayExpansionPolicy = overlayExpansionPolicy
    self.allowedLinkSchemes = allowedLinkSchemes
    self.showsSkeletonWhileLoading = showsSkeletonWhileLoading
  }

  /// Maps to a carousel configuration for the internal pager.
  public var resolvedCarouselConfiguration: FKCarouselConfiguration {
    carousel
  }
}
