import UIKit

/// Factory presets for ``FKCarousel``.
public enum FKCarouselPresets {
  /// Full-bleed carousel with bottom dot indicator overlay.
  public static func fullWidth(
    aspectRatio: CGFloat = 16.0 / 9.0,
    autoScrollInterval: TimeInterval? = nil
  ) -> FKCarouselConfiguration {
    var config = FKCarouselConfiguration(
      layout: .init(
        layoutMode: .fullPage,
        heightStrategy: .aspectRatio(aspectRatio)
      ),
      indicator: .init(
        style: .dots,
        placement: .overlayBottom(inset: 12)
      )
    )
    if let autoScrollInterval {
      config.autoScroll.isEnabled = true
      config.autoScroll.interval = autoScrollInterval
    }
    return config
  }

  /// E-commerce peek card layout with rounded pages.
  public static func cardPeek(
    aspectRatio: CGFloat = 16.0 / 9.0,
    peekWidth: CGFloat = 24,
    interPageSpacing: CGFloat = 12
  ) -> FKCarouselConfiguration {
    FKCarouselConfiguration(
      layout: .init(
        layoutMode: .cardPeek(interPageSpacing: interPageSpacing, peekWidth: peekWidth),
        heightStrategy: .aspectRatio(aspectRatio),
        isInfiniteLoopEnabled: true
      ),
      indicator: .init(
        style: .dots,
        placement: .below(spacing: 8)
      ),
      autoScroll: .init(isEnabled: true, interval: 4.0)
    )
  }

  /// Onboarding-style bounded pager with fraction indicator.
  public static func onboarding(aspectRatio: CGFloat = 4.0 / 3.0) -> FKCarouselConfiguration {
    FKCarouselConfiguration(
      layout: .init(
        layoutMode: .fullPage,
        heightStrategy: .aspectRatio(aspectRatio),
        isInfiniteLoopEnabled: false
      ),
      indicator: .init(
        style: .fraction,
        placement: .below(spacing: 12)
      ),
      autoScroll: .init(isEnabled: false)
    )
  }
}
