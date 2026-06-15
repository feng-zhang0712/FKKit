import Foundation

/// Identifiers and snapshot builder for ``FKListSkeletonPolicy/presetRows(count:)`` placeholder rows.
public enum FKListSkeletonPlaceholder {
  /// Prefix for placeholder item ids applied during initial loading.
  public static let itemIDPrefix = "__fklist_skeleton_"

  /// Cell type identifier registered by table list view controllers.
  public static let cellTypeIdentifier = "FKListSkeletonPlaceholderTableCell"

  /// Collection cell type identifier registered by collection list view controllers.
  public static let collectionCellTypeIdentifier = "FKListSkeletonPlaceholderCollectionCell"

  /// Recommended row/item height for ``presetRows`` placeholders (44pt avatar + 12pt vertical inset).
  public static let recommendedItemHeight: CGFloat = 68

  /// Payload token stored in the item store for placeholder cells.
  public struct Context: Sendable {
    public init() {}
  }

  /// Returns whether `id` belongs to a skeleton placeholder row.
  public static func isPlaceholderItemID(_ id: FKListItemID) -> Bool {
    id.rawValue.hasPrefix(itemIDPrefix)
  }

  /// Builds a single-section placeholder snapshot for initial loading.
  /// - Parameters:
  ///   - rowCount: Number of placeholder rows.
  ///   - sectionID: Target section identifier.
  ///   - cellTypeIdentifier: Registered custom cell id — use ``collectionCellTypeIdentifier`` for collection lists.
  public static func makeSnapshot(
    rowCount: Int,
    sectionID: FKListSectionID = "main",
    cellTypeIdentifier: String = Self.cellTypeIdentifier
  ) -> FKListSnapshot {
    let count = max(1, rowCount)
    let items = (0 ..< count).map { index in
      FKListItem.custom(
        id: FKListItemID("\(itemIDPrefix)\(index)"),
        cellTypeIdentifier: cellTypeIdentifier
      )
    }
    return FKListSnapshot(sections: [FKListSection(id: sectionID, items: items)])
  }
}
