import Foundation

// MARK: - Snapshot

/// Immutable list content model applied to diffable data sources.
public struct FKListSnapshot: Hashable, Sendable {
  public var sections: [FKListSection]

  public init(sections: [FKListSection] = []) {
    self.sections = sections
  }

  /// Total item count across all sections.
  public var totalItemCount: Int {
    sections.reduce(0) { $0 + $1.items.count }
  }

  /// Returns the item for `id` when present in this snapshot.
  public func item(withID id: FKListItemID) -> FKListItem? {
    for section in sections {
      if let item = section.items.first(where: { $0.id == id }) {
        return item
      }
    }
    return nil
  }

  /// Returns the section for `id` when present.
  public func section(withID id: FKListSectionID) -> FKListSection? {
    sections.first(where: { $0.id == id })
  }

  /// Item ids present in both snapshots whose row content changed (e.g. switch/checkbox state).
  public func itemIDsWithChangedContent(comparedTo previous: FKListSnapshot) -> [FKListItemID] {
    sections.flatMap(\.items).compactMap { item in
      guard let prior = previous.item(withID: item.id), prior != item else { return nil }
      return item.id
    }
  }
}

// MARK: - Mutation

/// Incremental snapshot operations; prefer append on load-more instead of full replace.
public enum FKListSnapshotMutation: Sendable {
  case replace(FKListSnapshot)
  case appendItems([FKListItem], toSection: FKListSectionID)
  case insertItems([(FKListItem, after: FKListItemID?)], inSection: FKListSectionID)
  case deleteItems([FKListItemID])
  case reloadItems([FKListItemID])
  case reloadSections([FKListSectionID])
}
