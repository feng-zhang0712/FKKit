import UIKit

/// Factory presets for ``FKImageBanner``.
public enum FKImageBannerPresets {
  /// Home hero banner: 16:9, infinite loop, 4s auto-scroll.
  public static func homeHero() -> FKImageBannerConfiguration {
    var carousel = FKCarouselPresets.fullWidth(aspectRatio: 16.0 / 9.0, autoScrollInterval: 4.0)
    carousel.layout.isInfiniteLoopEnabled = true
    carousel.autoScroll.isEnabled = true
    carousel.autoScroll.interval = 4.0
    return FKImageBannerConfiguration(
      carousel: carousel,
      overlayVisibility: .always,
      defaultCTATitle: nil,
      cardStyle: nil
    )
  }

  /// Compact promo strip with peek cards.
  public static func compactPromo() -> FKImageBannerConfiguration {
    FKImageBannerConfiguration(
      carousel: FKCarouselPresets.cardPeek(aspectRatio: 3.0 / 1.0, peekWidth: 20),
      overlayVisibility: .always,
      maximumTitleLines: 1,
      maximumSubtitleLines: 1,
      cardStyle: .init(cornerRadius: 10, usesCornerShadow: true)
    )
  }

  /// Edge-to-edge hero without card inset.
  public static func edgeToEdge() -> FKImageBannerConfiguration {
    var config = homeHero()
    config.carousel.layout.layoutMode = .fullPage
    config.cardStyle = nil
    return config
  }

  /// Onboarding slides without loop or auto-scroll.
  public static func onboarding() -> FKImageBannerConfiguration {
    FKImageBannerConfiguration(
      carousel: FKCarouselPresets.onboarding(),
      overlayVisibility: .always,
      maximumTitleLines: 2,
      maximumSubtitleLines: 2
    )
  }
}
