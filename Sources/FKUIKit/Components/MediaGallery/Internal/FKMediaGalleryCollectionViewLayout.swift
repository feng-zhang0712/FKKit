import UIKit

/// Horizontal paging collection view that blocks page swipes while the current page is zoomed or scrubbing.
@MainActor
final class FKMediaGalleryCollectionView: UICollectionView {
  var shouldAllowHorizontalPaging: (() -> Bool)?

  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer === panGestureRecognizer, shouldAllowHorizontalPaging?() == false {
      return false
    }
    return super.gestureRecognizerShouldBegin(gestureRecognizer)
  }
}

final class FKMediaGalleryCollectionViewLayout: UICollectionViewFlowLayout {
  override func prepare() {
    super.prepare()
    scrollDirection = .horizontal
    minimumLineSpacing = 0
    minimumInteritemSpacing = 0
    if let collectionView {
      itemSize = collectionView.bounds.size
    }
  }

  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    true
  }

  override func targetContentOffset(
    forProposedContentOffset proposedContentOffset: CGPoint,
    withScrollingVelocity velocity: CGPoint
  ) -> CGPoint {
    guard let collectionView else { return proposedContentOffset }
    let pageWidth = collectionView.bounds.width
    guard pageWidth > 0 else { return proposedContentOffset }
    let approximatePage = collectionView.contentOffset.x / pageWidth
    let page: CGFloat
    if velocity.x > 0 {
      page = ceil(approximatePage)
    } else if velocity.x < 0 {
      page = floor(approximatePage)
    } else {
      page = round(approximatePage)
    }
    return CGPoint(x: page * pageWidth, y: proposedContentOffset.y)
  }
}
