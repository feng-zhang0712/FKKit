import UIKit

/// Horizontal flow layout that sizes carousel pages and supports peek/card modes.
final class FKCarouselFlowLayout: UICollectionViewFlowLayout {
  var pageWidth: CGFloat = 0
  var pageHeight: CGFloat = 0

  override init() {
    super.init()
    scrollDirection = .horizontal
    minimumLineSpacing = 0
    minimumInteritemSpacing = 0
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    true
  }

  override func targetContentOffset(
    forProposedContentOffset proposedContentOffset: CGPoint,
    withScrollingVelocity velocity: CGPoint
  ) -> CGPoint {
    guard let collectionView, pageWidth > 0 else {
      return super.targetContentOffset(
        forProposedContentOffset: proposedContentOffset,
        withScrollingVelocity: velocity
      )
    }

    let pageSpan = pageWidth + minimumLineSpacing
    let rawIndex = proposedContentOffset.x / pageSpan
    let roundedIndex: CGFloat
    if velocity.x > 0.3 {
      roundedIndex = ceil(rawIndex - 0.01)
    } else if velocity.x < -0.3 {
      roundedIndex = floor(rawIndex + 0.01)
    } else {
      roundedIndex = round(rawIndex)
    }

    let maxIndex = max(0, CGFloat(collectionView.numberOfItems(inSection: 0) - 1))
    let clampedIndex = min(max(0, roundedIndex), maxIndex)
    let x = clampedIndex * pageSpan
    return CGPoint(x: x, y: proposedContentOffset.y)
  }
}
