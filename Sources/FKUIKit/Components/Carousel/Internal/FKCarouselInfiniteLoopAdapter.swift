import Foundation

/// Maps logical page indices to physical collection indices for infinite looping.
struct FKCarouselInfiniteLoopAdapter {
  let isEnabled: Bool
  let logicalCount: Int

  var isActive: Bool {
    isEnabled && logicalCount >= 2
  }

  var physicalCount: Int {
    guard isActive else { return logicalCount }
    return logicalCount + 2
  }

  func physicalIndex(forLogical logicalIndex: Int) -> Int {
    guard isActive else { return logicalIndex }
    return logicalIndex + 1
  }

  func logicalIndex(forPhysical physicalIndex: Int) -> Int {
    guard isActive else { return physicalIndex }
    if physicalIndex == 0 {
      return logicalCount - 1
    }
    if physicalIndex == logicalCount + 1 {
      return 0
    }
    return physicalIndex - 1
  }

  func initialPhysicalIndex(forLogical logicalIndex: Int) -> Int {
    physicalIndex(forLogical: min(max(0, logicalIndex), max(0, logicalCount - 1)))
  }

  func loopCorrection(
    physicalIndex: Int
  ) -> (targetPhysicalIndex: Int, reason: FKCarouselPageChangeReason)? {
    guard isActive else { return nil }
    if physicalIndex == 0 {
      return (logicalCount, .loopCorrection)
    }
    if physicalIndex == logicalCount + 1 {
      return (1, .loopCorrection)
    }
    return nil
  }
}
