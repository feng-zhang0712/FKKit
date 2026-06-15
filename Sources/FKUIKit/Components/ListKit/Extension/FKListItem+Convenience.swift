import Foundation

public extension FKListItem {
  /// Creates a preset text row.
  static func text(id: FKListItemID, title: String) -> FKListItem {
    FKListItem(id: id, kind: .preset(.text(FKListTextRow(title: title))))
  }

  /// Creates a preset subtitle row.
  static func subtitle(id: FKListItemID, title: String, subtitle: String?) -> FKListItem {
    FKListItem(id: id, kind: .preset(.subtitle(FKListSubtitleRow(title: title, subtitle: subtitle))))
  }

  /// Creates a custom row bound to a registered cell identifier.
  ///
  /// ``cellTypeIdentifier`` must match the registry key from
  /// ``FKDiffableTableViewController/register(_:forPayloadType:)`` (typically `String(describing: MyCell.self)`).
  /// Pair with ``FKDiffableTableViewController/setPayload(_:for:)`` before applying the snapshot.
  static func custom(id: FKListItemID, cellTypeIdentifier: String) -> FKListItem {
    FKListItem(id: id, kind: .custom(FKListCustomItem(cellTypeIdentifier: cellTypeIdentifier)))
  }
}

public extension FKListSection {
  /// Single-section snapshot convenience for feeds.
  static func main(items: [FKListItem]) -> FKListSection {
    FKListSection(id: "main", items: items)
  }
}

public extension FKListSnapshot {
  /// Convenience initializer for a single-section list.
  init(items: [FKListItem], sectionID: FKListSectionID = "main") {
    self.init(sections: [FKListSection(id: sectionID, items: items)])
  }
}
