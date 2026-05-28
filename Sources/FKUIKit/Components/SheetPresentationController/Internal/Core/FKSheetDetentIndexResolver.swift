import CoreGraphics

/// Resolves detent indices from resolved heights (order-independent).
enum FKSheetDetentIndexResolver {
  private static let heightEqualityTolerance: CGFloat = 0.5

  /// Index of the smallest resolved detent height (first match on ties).
  static func smallestIndex(in resolvedHeights: [CGFloat]) -> Int {
    guard !resolvedHeights.isEmpty else { return 0 }
    guard let minimumHeight = resolvedHeights.min() else { return 0 }
    return resolvedHeights.firstIndex(where: { abs($0 - minimumHeight) <= heightEqualityTolerance }) ?? 0
  }

  /// Index of the largest resolved detent height (last match on ties).
  static func largestIndex(in resolvedHeights: [CGFloat]) -> Int {
    guard !resolvedHeights.isEmpty else { return 0 }
    guard let maximumHeight = resolvedHeights.max() else { return 0 }
    return resolvedHeights.lastIndex(where: { abs($0 - maximumHeight) <= heightEqualityTolerance }) ?? resolvedHeights.count - 1
  }

  /// Next taller detent relative to `currentIndex`, or `currentIndex` when already at the largest height.
  static func nextTallerIndex(from currentIndex: Int, in resolvedHeights: [CGFloat]) -> Int {
    guard resolvedHeights.indices.contains(currentIndex) else { return largestIndex(in: resolvedHeights) }
    let currentHeight = resolvedHeights[currentIndex]
    var candidate: Int?
    var candidateHeight = CGFloat.greatestFiniteMagnitude
    for (index, height) in resolvedHeights.enumerated() where height > currentHeight + heightEqualityTolerance {
      if height < candidateHeight {
        candidateHeight = height
        candidate = index
      }
    }
    return candidate ?? currentIndex
  }

  /// Next shorter detent relative to `currentIndex`, or `currentIndex` when already at the smallest height.
  static func nextShorterIndex(from currentIndex: Int, in resolvedHeights: [CGFloat]) -> Int {
    guard resolvedHeights.indices.contains(currentIndex) else { return smallestIndex(in: resolvedHeights) }
    let currentHeight = resolvedHeights[currentIndex]
    var candidate: Int?
    var candidateHeight = CGFloat.leastNormalMagnitude
    for (index, height) in resolvedHeights.enumerated() where height < currentHeight - heightEqualityTolerance {
      if height > candidateHeight {
        candidateHeight = height
        candidate = index
      }
    }
    return candidate ?? currentIndex
  }
}
