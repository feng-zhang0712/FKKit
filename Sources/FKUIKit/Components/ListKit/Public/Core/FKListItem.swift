import Foundation

// MARK: - Metadata

/// Optional per-item flags consumed by preset cells and selection logic.
public struct FKListItemMetadata: Hashable, Sendable {
  public var isEnabled: Bool
  public var isSelectable: Bool

  public init(isEnabled: Bool = true, isSelectable: Bool = true) {
    self.isEnabled = isEnabled
    self.isSelectable = isSelectable
  }
}

// MARK: - Custom item

/// Host-registered cell binding; payload is stored separately in the list controller item store.
public struct FKListCustomItem: Hashable, Sendable {
  public var cellTypeIdentifier: String

  public init(cellTypeIdentifier: String) {
    self.cellTypeIdentifier = cellTypeIdentifier
  }
}

// MARK: - Item kind

/// Describes how a list row is rendered.
public enum FKListItemKind: Hashable, Sendable {
  case preset(FKListPresetItem)
  case custom(FKListCustomItem)
}

// MARK: - Item

/// Hashable list row envelope used by ``FKListSnapshot``.
public struct FKListItem: Hashable, Sendable {
  public var id: FKListItemID
  public var kind: FKListItemKind
  public var metadata: FKListItemMetadata?
  public var swipeActions: FKListSwipeActionConfiguration?

  public init(
    id: FKListItemID,
    kind: FKListItemKind,
    metadata: FKListItemMetadata? = nil,
    swipeActions: FKListSwipeActionConfiguration? = nil
  ) {
    self.id = id
    self.kind = kind
    self.metadata = metadata
    self.swipeActions = swipeActions
  }
}
