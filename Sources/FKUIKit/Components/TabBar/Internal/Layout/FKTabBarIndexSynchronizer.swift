import Foundation

@MainActor
enum FKTabBarIndexSynchronizer {
  /// Resolves next selected index after dynamic item updates.
  ///
  /// Selection policy is centralized here so reducer inputs stay deterministic even when
  /// visibility/enabled states change concurrently with host data mutations.
  static func clamp(_ index: Int, count: Int) -> Int {
    guard count > 0 else { return 0 }
    return min(max(0, index), count - 1)
  }

  static func resolveTargetIndex(
    previousVisibleID: String?,
    previousSelectedIndex: Int,
    visibleItems: [FKTabBarItem],
    policy: FKTabBar.ItemsUpdatePolicy
  ) -> Int {
    // Policy rules (high level):
    // - preserveSelection: prefer stable ID mapping; if that tab is disabled, fall back to nearest enabled item.
    // - resetSelection: always select the first visible item.
    // - nearestAvailable: pick the closest enabled item to minimize user surprise when
    //   the selected item disappears or becomes disabled.
    guard !visibleItems.isEmpty else { return 0 }
    switch policy {
    case .resetSelection:
      return 0
    case .preserveSelection:
      if let previousVisibleID, let idx = visibleItems.firstIndex(where: { $0.id == previousVisibleID }) {
        if visibleItems[idx].isEnabled {
          return idx
        }
        return nearestSelectableIndex(from: idx, visibleItems: visibleItems)
      }
      let clamped = clamp(previousSelectedIndex, count: visibleItems.count)
      if visibleItems.indices.contains(clamped), visibleItems[clamped].isEnabled {
        return clamped
      }
      return nearestSelectableIndex(from: clamped, visibleItems: visibleItems)
    case .nearestAvailable:
      return nearestSelectableIndex(from: previousSelectedIndex, visibleItems: visibleItems)
    }
  }

  static func nearestSelectableIndex(from index: Int, visibleItems: [FKTabBarItem]) -> Int {
    // "Nearest" searches both directions so inserts/removals feel stable even when host
    // performs a batch update. Returning 0 is a safe fallback when all items are disabled.
    guard !visibleItems.isEmpty else { return 0 }
    if visibleItems.indices.contains(index), visibleItems[index].isEnabled { return index }
    var left = index - 1
    var right = index + 1
    while left >= 0 || right < visibleItems.count {
      if left >= 0, visibleItems[left].isEnabled { return left }
      if right < visibleItems.count, visibleItems[right].isEnabled { return right }
      left -= 1
      right += 1
    }
    return 0
  }
}
