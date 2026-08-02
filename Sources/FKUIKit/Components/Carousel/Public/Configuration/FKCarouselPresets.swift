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
      paging: .init(decelerationRate: .fast, bounces: false),
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

  /// Centered focus cards with side peek, neighbor scale-down, and expanding line indicator.
  ///
  /// Pair with custom ``FKCarousel/pageProvider`` image cards. Defaults enable indicator taps,
  /// side-card taps, fast deceleration, and bounce-off for seamless infinite looping.
  public static func focusedCards(
    pageWidth: CGFloat = 280,
    height: CGFloat = 180,
    interPageSpacing: CGFloat = 14,
    sidePageScale: CGFloat = 0.88
  ) -> FKCarouselConfiguration {
    FKCarouselConfiguration(
      layout: .init(
        layoutMode: .fixedPageWidth(pageWidth),
        heightStrategy: .fixed(height),
        interPageSpacing: interPageSpacing,
        clipsToBounds: false,
        isInfiniteLoopEnabled: true
      ),
      paging: .init(decelerationRate: .fast, bounces: false),
      indicator: .init(
        style: .line,
        placement: .below(spacing: 14),
        activeColor: .systemBlue,
        inactiveColor: UIColor.tertiaryLabel.withAlphaComponent(0.55),
        activeLineWidth: 22,
        inactiveLineWidth: 8,
        lineThickness: 4,
        allowsPageSelection: true
      ),
      autoScroll: .init(isEnabled: false),
      interaction: .init(scrollsToTappedPage: true),
      motion: .init(sidePageScale: sidePageScale)
    )
  }
}
