import UIKit

/// Measures overlay content height for ``FKImageBannerOverlayExpansionPolicy/growBanner``.
enum FKImageBannerOverlayMetrics {
  /// Extra banner height required beyond the base aspect-ratio height.
  static func additionalBannerHeight(
    slide: FKImageBannerSlide?,
    configuration: FKImageBannerConfiguration,
    pageWidth: CGFloat,
    traitCollection: UITraitCollection
  ) -> CGFloat {
    guard configuration.overlayExpansionPolicy == .growBanner else { return 0 }
    guard pageWidth > 0, let slide else { return 0 }

    let baseHeight = FKCarouselLayoutEngine.resolvedHeight(
      width: pageWidth,
      strategy: configuration.carousel.layout.heightStrategy
    )
    guard baseHeight > 0 else { return 0 }

    let overlayContentHeight = measuredOverlayContentHeight(
      slide: slide,
      configuration: configuration,
      contentWidth: max(0, pageWidth - 32),
      traitCollection: traitCollection
    )
    guard overlayContentHeight > 0 else { return 0 }

    let overlayBudget = min(baseHeight * 0.42, 160)
    return max(0, overlayContentHeight - overlayBudget)
  }

  private static func measuredOverlayContentHeight(
    slide: FKImageBannerSlide,
    configuration: FKImageBannerConfiguration,
    contentWidth: CGFloat,
    traitCollection: UITraitCollection
  ) -> CGFloat {
    let visibility = slide.overlayStyle?.visibility ?? configuration.overlayVisibility
    guard visibility == .always || visibility == .accessibilityOnly else { return 0 }

    let ctaTitle = slide.overlayStyle?.ctaTitle ?? configuration.defaultCTATitle
    let showsCTA = visibility == .always && ctaTitle?.isEmpty == false
    let hasTitle = slide.title?.isEmpty == false
    let hasSubtitle = slide.subtitle?.isEmpty == false
    guard showsCTA || hasTitle || hasSubtitle else { return 0 }

    var height: CGFloat = 16

    if showsCTA {
      height += 44
    }

    if hasTitle || hasSubtitle {
      if showsCTA {
        height += 8
      }

      if hasSubtitle {
        height += measuredLabelHeight(
          text: slide.subtitle,
          textStyle: .subheadline,
          maximumLines: configuration.maximumSubtitleLines,
          contentWidth: contentWidth,
          traitCollection: traitCollection
        )
      }

      if hasTitle {
        if hasSubtitle {
          height += 4
        }
        height += measuredLabelHeight(
          text: slide.title,
          textStyle: .headline,
          maximumLines: configuration.maximumTitleLines,
          contentWidth: contentWidth,
          traitCollection: traitCollection
        )
      }
    }

    return height
  }

  private static func measuredLabelHeight(
    text: String?,
    textStyle: UIFont.TextStyle,
    maximumLines: Int,
    contentWidth: CGFloat,
    traitCollection: UITraitCollection
  ) -> CGFloat {
    guard let text, !text.isEmpty, contentWidth > 0, maximumLines > 0 else { return 0 }

    var measuredHeight: CGFloat = 0
    traitCollection.performAsCurrent {
      let label = UILabel()
      label.numberOfLines = maximumLines
      label.adjustsFontForContentSizeCategory = true
      label.text = text
      label.font = UIFont.preferredFont(forTextStyle: textStyle)
      label.preferredMaxLayoutWidth = contentWidth

      let size = label.sizeThatFits(
        CGSize(width: contentWidth, height: UIView.layoutFittingCompressedSize.height)
      )
      measuredHeight = ceil(size.height)
    }
    return measuredHeight
  }
}
