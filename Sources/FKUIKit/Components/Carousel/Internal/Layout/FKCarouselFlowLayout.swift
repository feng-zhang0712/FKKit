import UIKit

/// Horizontal flow layout that sizes carousel pages and supports peek/card modes.
final class FKCarouselFlowLayout: UICollectionViewFlowLayout {
  var pageWidth: CGFloat = 0
  var pageHeight: CGFloat = 0

  /// Scale applied one page-span from the focus center. `1` disables transforms.
  var sidePageScale: CGFloat = 1

  /// When infinite looping is active, snap at most one page per gesture.
  var isInfiniteLoopActive = false

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

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
    guard shouldApplyFocusScale else { return attributes }
    return attributes.map { attribute in
      let copy = attribute.copy() as! UICollectionViewLayoutAttributes
      applyFocusScale(to: copy)
      return copy
    }
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard let attribute = super.layoutAttributesForItem(at: indexPath) else { return nil }
    guard shouldApplyFocusScale else { return attribute }
    let copy = attribute.copy() as! UICollectionViewLayoutAttributes
    applyFocusScale(to: copy)
    return copy
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
    guard pageSpan > 0 else {
      return super.targetContentOffset(
        forProposedContentOffset: proposedContentOffset,
        withScrollingVelocity: velocity
      )
    }

    let maxIndex = max(0, CGFloat(collectionView.numberOfItems(inSection: 0) - 1))
    let currentIndex = (collectionView.contentOffset.x / pageSpan).rounded()
    let projectedIndex = (proposedContentOffset.x / pageSpan).rounded()

    // Infinite / focus carousels: advance at most one page so a fast fling cannot
    // leap onto a clone sentinel and appear to reverse across the whole strip.
    let targetIndex: CGFloat
    if isInfiniteLoopActive {
      if velocity.x > 0.3 {
        targetIndex = currentIndex + 1
      } else if velocity.x < -0.3 {
        targetIndex = currentIndex - 1
      } else {
        targetIndex = projectedIndex
      }
    } else if velocity.x > 0.3 {
      targetIndex = ceil(proposedContentOffset.x / pageSpan - 0.01)
    } else if velocity.x < -0.3 {
      targetIndex = floor(proposedContentOffset.x / pageSpan + 0.01)
    } else {
      targetIndex = projectedIndex
    }

    let clampedIndex = min(max(0, targetIndex), maxIndex)
    return CGPoint(x: clampedIndex * pageSpan, y: proposedContentOffset.y)
  }

  private var shouldApplyFocusScale: Bool {
    sidePageScale < 1 - .ulpOfOne && !UIAccessibility.isReduceMotionEnabled
  }

  private func applyFocusScale(to attributes: UICollectionViewLayoutAttributes) {
    guard attributes.representedElementCategory == .cell,
          let collectionView,
          pageWidth > 0
    else { return }

    let pageSpan = pageWidth + minimumLineSpacing
    guard pageSpan > 0 else { return }

    let focusX = collectionView.contentOffset.x + collectionView.bounds.width / 2
    let distance = abs(attributes.center.x - focusX)
    let normalized = min(1, distance / pageSpan)
    let scale = 1 - ((1 - sidePageScale) * normalized)
    attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
    attributes.zIndex = Int((1 - normalized) * 100)
  }
}
