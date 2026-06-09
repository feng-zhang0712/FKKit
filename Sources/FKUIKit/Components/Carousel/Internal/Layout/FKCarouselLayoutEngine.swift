import UIKit

/// Computes carousel geometry from layout configuration and container bounds.
enum FKCarouselLayoutEngine {
  struct Metrics: Equatable {
    var pageWidth: CGFloat
    var pageHeight: CGFloat
    var itemSize: CGSize
    var sectionInset: UIEdgeInsets
    var pageSpan: CGFloat
    var collectionHeight: CGFloat
    var indicatorSpacing: CGFloat
    var usesPagingEnabled: Bool
  }

  static func metrics(
    bounds: CGRect,
    configuration: FKCarouselConfiguration,
    safeAreaInsets: UIEdgeInsets,
    intrinsicPageHeightResolver: ((CGFloat) -> CGFloat)? = nil
  ) -> Metrics {
    let layout = configuration.layout
    let indicator = configuration.indicator
    let contentInsets = layout.contentInsets
    let availableWidth = max(0, bounds.width - contentInsets.left - contentInsets.right)

    var pageWidth = availableWidth
    var sectionInset = UIEdgeInsets(
      top: contentInsets.top,
      left: contentInsets.left,
      bottom: contentInsets.bottom,
      right: contentInsets.right
    )
    var interItemSpacing = layout.interPageSpacing
    var usesPagingEnabled = false

    switch layout.layoutMode {
    case .fullPage:
      pageWidth = availableWidth
      usesPagingEnabled = interItemSpacing == 0

    case let .cardPeek(spacing, peekWidth):
      interItemSpacing = spacing
      pageWidth = max(0, availableWidth - peekWidth - spacing)
      sectionInset.left = contentInsets.left
      sectionInset.right = contentInsets.right + peekWidth

    case let .fixedPageWidth(width):
      pageWidth = min(width, availableWidth)
      let horizontalInset = max(0, (availableWidth - pageWidth) / 2)
      sectionInset.left += horizontalInset
      sectionInset.right += horizontalInset

    case let .insetCard(_, horizontalInset):
      interItemSpacing = layout.interPageSpacing
      pageWidth = max(0, availableWidth - horizontalInset * 2)
      sectionInset.left += horizontalInset
      sectionInset.right += horizontalInset
    }

    let pageHeight: CGFloat
    switch layout.heightStrategy {
    case .intrinsicFromCurrentPage:
      pageHeight = max(0, intrinsicPageHeightResolver?(pageWidth) ?? 0)
    default:
      pageHeight = resolvedHeight(width: pageWidth, strategy: layout.heightStrategy)
    }

    let indicatorSpacing: CGFloat
    switch indicator.placement {
    case let .below(spacing), let .above(spacing):
      indicatorSpacing = spacing
    case .overlayBottom, .overlayTop:
      indicatorSpacing = 0
    }

    let collectionHeight = pageHeight
    let pageSpan = pageWidth + interItemSpacing

    return Metrics(
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      itemSize: CGSize(width: pageWidth, height: pageHeight),
      sectionInset: sectionInset,
      pageSpan: pageSpan,
      collectionHeight: collectionHeight,
      indicatorSpacing: indicatorSpacing,
      usesPagingEnabled: usesPagingEnabled
    )
  }

  static func resolvedHeight(width: CGFloat, strategy: FKCarouselHeightStrategy) -> CGFloat {
    switch strategy {
    case let .fixed(height):
      return height
    case let .aspectRatio(ratio):
      guard ratio > 0 else { return 0 }
      return width / ratio
    case .intrinsicFromCurrentPage:
      return 0
    }
  }

  static func contentOffset(
    forPhysicalIndex index: Int,
    metrics: Metrics
  ) -> CGPoint {
    CGPoint(x: CGFloat(index) * metrics.pageSpan, y: 0)
  }

  static func physicalIndex(
    forContentOffset offset: CGPoint,
    metrics: Metrics,
    pageCount: Int
  ) -> Int {
    guard metrics.pageSpan > 0, pageCount > 0 else { return 0 }
    let raw = offset.x / metrics.pageSpan
    return min(max(0, Int(round(raw))), max(0, pageCount - 1))
  }

  static func scrollProgress(
    forContentOffset offset: CGPoint,
    metrics: Metrics,
    pageCount: Int,
    clampToPageBounds: Bool = true
  ) -> (progress: CGFloat, fromPage: Int, toPage: Int) {
    guard metrics.pageSpan > 0, pageCount > 0 else {
      return (0, 0, 0)
    }

    let raw = offset.x / metrics.pageSpan
    let lastPage = max(0, pageCount - 1)

    if clampToPageBounds, raw < 0 {
      return (0, 0, min(1, lastPage))
    }
    if clampToPageBounds, raw > CGFloat(lastPage) {
      return (0, lastPage, lastPage)
    }

    let from = min(max(0, Int(floor(raw))), lastPage)
    let to = min(max(0, from + 1), lastPage)
    let progress = raw - floor(raw)
    return (progress, from, to)
  }
}
