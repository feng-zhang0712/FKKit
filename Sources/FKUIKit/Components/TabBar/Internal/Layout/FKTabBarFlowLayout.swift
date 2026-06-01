import UIKit

/// Horizontal flow layout that honors per-gap spacing from ``FKTabBarCustomization/customSpacing(after:context:)``.
@MainActor
final class FKTabBarFlowLayout: UICollectionViewFlowLayout {
  /// When non-`nil`, spacing after each visible index overrides ``minimumLineSpacing``.
  var spacingAfterIndex: ((Int) -> CGFloat?)?

  private struct LayoutMetrics {
    var frames: [CGRect]
    var contentSize: CGSize
  }

  private var usesVariableSpacing: Bool {
    spacingAfterIndex != nil
  }

  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    true
  }

  override var collectionViewContentSize: CGSize {
    guard usesVariableSpacing, let collectionView else {
      return super.collectionViewContentSize
    }
    return layoutMetrics(in: collectionView).contentSize
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard usesVariableSpacing, let collectionView else {
      return super.layoutAttributesForElements(in: rect)
    }

    let metrics = layoutMetrics(in: collectionView)
    guard !metrics.frames.isEmpty else { return [] }

    var attributes: [UICollectionViewLayoutAttributes] = []
    for (index, frame) in metrics.frames.enumerated() where frame.intersects(rect) {
      let indexPath = IndexPath(item: index, section: 0)
      let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
      attr.frame = frame
      attributes.append(attr)
    }
    return attributes
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard usesVariableSpacing, let collectionView else {
      return super.layoutAttributesForItem(at: indexPath)
    }

    let metrics = layoutMetrics(in: collectionView)
    guard metrics.frames.indices.contains(indexPath.item) else { return nil }
    let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
    attr.frame = metrics.frames[indexPath.item]
    return attr
  }

  private func layoutMetrics(in collectionView: UICollectionView) -> LayoutMetrics {
    let itemCount = collectionView.numberOfItems(inSection: 0)
    guard itemCount > 0 else {
      return LayoutMetrics(frames: [], contentSize: super.collectionViewContentSize)
    }

    var sizes: [CGSize] = []
    sizes.reserveCapacity(itemCount)
    var maxHeight = CGFloat.zero
    for index in 0..<itemCount {
      let indexPath = IndexPath(item: index, section: 0)
      let size = resolvedItemSize(at: indexPath, in: collectionView)
      sizes.append(size)
      maxHeight = max(maxHeight, size.height)
    }

    var itemsWidth = sizes.map(\.width).reduce(0, +)
    if itemCount > 1 {
      for index in 0..<(itemCount - 1) {
        itemsWidth += resolvedSpacing(after: index)
      }
    }

    let contentWidth = sectionInset.left + itemsWidth + sectionInset.right
    let contentHeight = maxHeight + sectionInset.top + sectionInset.bottom
    let isRTL = collectionView.effectiveUserInterfaceLayoutDirection == .rightToLeft
    let y = sectionInset.top

    var frames: [CGRect] = []
    frames.reserveCapacity(itemCount)

    if isRTL {
      var x = contentWidth - sectionInset.right
      for index in 0..<itemCount {
        let size = sizes[index]
        x -= size.width
        frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
        if index < itemCount - 1 {
          x -= resolvedSpacing(after: index)
        }
      }
    } else {
      var x = sectionInset.left
      for index in 0..<itemCount {
        let size = sizes[index]
        frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
        x += size.width
        if index < itemCount - 1 {
          x += resolvedSpacing(after: index)
        }
      }
    }

    return LayoutMetrics(
      frames: frames,
      contentSize: CGSize(width: contentWidth, height: contentHeight)
    )
  }

  private func resolvedSpacing(after index: Int) -> CGFloat {
    spacingAfterIndex?(index) ?? minimumLineSpacing
  }

  private func resolvedItemSize(at indexPath: IndexPath, in collectionView: UICollectionView) -> CGSize {
    if let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
       let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) {
      return size
    }
    return itemSize
  }
}
