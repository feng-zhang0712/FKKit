import Foundation

/// Applies ``FKListSnapshotMutation`` values to in-memory snapshots.
enum FKListSnapshotApplier {
  static func apply(_ mutation: FKListSnapshotMutation, to snapshot: inout FKListSnapshot) {
    switch mutation {
    case .replace(let newSnapshot):
      snapshot = newSnapshot

    case .appendItems(let items, let sectionID):
      guard let index = snapshot.sections.firstIndex(where: { $0.id == sectionID }) else { return }
      snapshot.sections[index].items.append(contentsOf: items)

    case .insertItems(let pairs, let sectionID):
      guard let sectionIndex = snapshot.sections.firstIndex(where: { $0.id == sectionID }) else { return }
      for (item, afterID) in pairs {
        if let afterID,
           let anchorIndex = snapshot.sections[sectionIndex].items.firstIndex(where: { $0.id == afterID }) {
          snapshot.sections[sectionIndex].items.insert(item, at: anchorIndex + 1)
        } else {
          snapshot.sections[sectionIndex].items.append(item)
        }
      }

    case .deleteItems(let ids):
      let idSet = Set(ids)
      for sectionIndex in snapshot.sections.indices {
        snapshot.sections[sectionIndex].items.removeAll { idSet.contains($0.id) }
      }

    case .reloadItems:
      break

    case .reloadSections:
      break
    }
  }

  static func duplicateItemIDs(in snapshot: FKListSnapshot) -> [FKListItemID] {
    var seen = Set<FKListItemID>()
    var duplicates: [FKListItemID] = []
    for section in snapshot.sections {
      for item in section.items {
        if seen.contains(item.id) {
          duplicates.append(item.id)
        } else {
          seen.insert(item.id)
        }
      }
    }
    return duplicates
  }
}
