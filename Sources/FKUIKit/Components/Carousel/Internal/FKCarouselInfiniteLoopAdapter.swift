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

  /// Chooses the closest physical index for a logical page relative to the current physical position.
  ///
  /// Used so adjacent side-card taps (and indicator jumps near the loop seam) animate one step
  /// instead of traveling the long way around the collection.
  func nearestPhysicalIndex(forLogical logicalIndex: Int, fromPhysical currentPhysicalIndex: Int) -> Int {
    guard isActive else { return logicalIndex }
    let clampedLogical = min(max(0, logicalIndex), max(0, logicalCount - 1))
    var candidates = [clampedLogical + 1]
    if clampedLogical == logicalCount - 1 {
      candidates.append(0)
    }
    if clampedLogical == 0 {
      candidates.append(logicalCount + 1)
    }
    return candidates.min(by: { abs($0 - currentPhysicalIndex) < abs($1 - currentPhysicalIndex) })
      ?? (clampedLogical + 1)
  }
}
