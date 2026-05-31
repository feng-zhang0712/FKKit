import Foundation

@MainActor
enum FKTabBarItemDiffEngine {
  enum Plan: Equatable {
    case contentUpdates(indices: [Int])
    case structural(removals: [Int], insertions: [Int])
    case fullReload
  }

  /// Plans the minimum collection update for a visible-strip transition.
  static func plan(oldVisible: [FKTabBarItem], newVisible: [FKTabBarItem]) -> Plan {
    let oldIDs = oldVisible.map(\.id)
    let newIDs = newVisible.map(\.id)

    guard oldIDs != newIDs else {
      let indices = zip(oldVisible, newVisible).enumerated().compactMap { index, pair in
        pair.0 != pair.1 ? index : nil
      }
      return .contentUpdates(indices: indices)
    }

    guard !oldVisible.isEmpty || !newVisible.isEmpty else {
      return .contentUpdates(indices: [])
    }

    let difference = newIDs.difference(from: oldIDs)
    let removals = difference.removals.compactMap { change -> Int? in
      guard case .remove(let offset, _, _) = change else { return nil }
      return offset
    }
    let insertions = difference.insertions.compactMap { change -> Int? in
      guard case .insert(let offset, _, _) = change else { return nil }
      return offset
    }

    guard removals.count + insertions.count <= max(oldVisible.count, newVisible.count) + 4 else {
      return .fullReload
    }

    return .structural(removals: removals, insertions: insertions)
  }
}

@MainActor
enum FKTabBarItemListMutator {
  /// Applies a single change to the visible strip and synchronizes ``FKTabBar/items``.
  static func apply(
    _ change: FKTabBarItemChange,
    visibleItems: inout [FKTabBarItem],
    items: inout [FKTabBarItem]
  ) throws {
    switch change.kind {
    case .insert(let item, let index):
      let clamped = min(max(0, index), visibleItems.count)
      var inserted = item
      inserted.isHidden = false
      visibleItems.insert(inserted, at: clamped)
      upsertFullListItem(inserted, visibleItems: visibleItems, items: &items)

    case .delete(let index):
      guard visibleItems.indices.contains(index) else {
        throw FKTabBarItemChangeError.invalidVisibleIndex(index)
      }
      let removedID = visibleItems[index].id
      visibleItems.remove(at: index)
      if let fullIndex = items.firstIndex(where: { $0.id == removedID }) {
        items[fullIndex].isHidden = true
      }

    case .move(let from, let to):
      guard visibleItems.indices.contains(from) else {
        throw FKTabBarItemChangeError.invalidVisibleIndex(from)
      }
      let clampedTo = min(max(0, to), max(0, visibleItems.count - 1))
      let moved = visibleItems.remove(at: from)
      visibleItems.insert(moved, at: clampedTo)
      reorderFullList(visibleItems: visibleItems, items: &items)

    case .update(let item, let index):
      guard visibleItems.indices.contains(index) else {
        throw FKTabBarItemChangeError.invalidVisibleIndex(index)
      }
      guard visibleItems[index].id == item.id else {
        throw FKTabBarItemChangeError.identifierMismatch(expected: visibleItems[index].id, received: item.id)
      }
      var updated = item
      updated.isHidden = false
      visibleItems[index] = updated
      if let fullIndex = items.firstIndex(where: { $0.id == item.id }) {
        items[fullIndex] = updated
      }
    }
  }

  private static func upsertFullListItem(
    _ item: FKTabBarItem,
    visibleItems: [FKTabBarItem],
    items: inout [FKTabBarItem]
  ) {
    if let fullIndex = items.firstIndex(where: { $0.id == item.id }) {
      items[fullIndex] = item
      reorderFullList(visibleItems: visibleItems, items: &items)
      return
    }
    insertIntoFullList(item, visibleItems: visibleItems, items: &items)
  }

  private static func insertIntoFullList(
    _ item: FKTabBarItem,
    visibleItems: [FKTabBarItem],
    items: inout [FKTabBarItem]
  ) {
    guard let visibleIndex = visibleItems.firstIndex(where: { $0.id == item.id }) else {
      items.append(item)
      return
    }
    let insertionIndex = fullListInsertionIndex(forVisibleIndex: visibleIndex, visibleItems: visibleItems, items: items)
    items.insert(item, at: insertionIndex)
  }

  private static func reorderFullList(visibleItems: [FKTabBarItem], items: inout [FKTabBarItem]) {
    let hiddenItems = items.filter(\.isHidden)
    var visibleLookup = Dictionary(uniqueKeysWithValues: items.filter { !$0.isHidden }.map { ($0.id, $0) })
    for visible in visibleItems {
      visibleLookup[visible.id] = visible
    }
    let orderedVisible = visibleItems.map { visibleLookup[$0.id] ?? $0 }
    items = orderedVisible + hiddenItems
  }

  private static func fullListInsertionIndex(
    forVisibleIndex visibleIndex: Int,
    visibleItems: [FKTabBarItem],
    items: [FKTabBarItem]
  ) -> Int {
    if visibleIndex == 0 {
      if let firstVisible = visibleItems.first,
         let existing = items.firstIndex(where: { $0.id == firstVisible.id && !$0.isHidden }) {
        return existing
      }
      return 0
    }
    let anchorID = visibleItems[visibleIndex - 1].id
    if let anchorIndex = items.firstIndex(where: { $0.id == anchorID }) {
      return anchorIndex + 1
    }
    return items.count
  }
}

enum FKTabBarItemChangeError: Error, Equatable {
  case invalidVisibleIndex(Int)
  case identifierMismatch(expected: String, received: String)
}
