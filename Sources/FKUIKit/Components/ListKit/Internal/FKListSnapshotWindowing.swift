import Foundation

/// Trims ``FKListSnapshot`` values to a maximum item count.
enum FKListSnapshotWindowing {
  struct Result {
    let snapshot: FKListSnapshot
    let removedItemIDs: [FKListItemID]
  }

  static func apply(
    to snapshot: FKListSnapshot,
    configuration: FKListWindowingConfiguration
  ) -> Result {
    guard configuration.isEnabled else {
      return Result(snapshot: snapshot, removedItemIDs: [])
    }
    let total = snapshot.totalItemCount
    guard total > configuration.maxItemCount else {
      return Result(snapshot: snapshot, removedItemIDs: [])
    }
    let overflow = total - configuration.maxItemCount
    switch configuration.trimStrategy {
    case .removeOldestItemsFromHead:
      return trimOldest(snapshot: snapshot, count: overflow)
    }
  }

  private static func trimOldest(snapshot: FKListSnapshot, count: Int) -> Result {
    guard count > 0, !snapshot.sections.isEmpty else {
      return Result(snapshot: snapshot, removedItemIDs: [])
    }
    var working = snapshot
    var removed: [FKListItemID] = []
    var remaining = count
    for sectionIndex in working.sections.indices {
      guard remaining > 0 else { break }
      let removable = min(remaining, working.sections[sectionIndex].items.count)
      if removable > 0 {
        let dropped = working.sections[sectionIndex].items.prefix(removable)
        removed.append(contentsOf: dropped.map(\.id))
        working.sections[sectionIndex].items.removeFirst(removable)
        remaining -= removable
      }
    }
    working.sections.removeAll { $0.items.isEmpty }
    return Result(snapshot: working, removedItemIDs: removed)
  }
}
