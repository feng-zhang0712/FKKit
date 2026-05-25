import Foundation

/// A grouped block of actions rendered as one inset table section.
public struct FKActionSheetSection: Identifiable, Equatable {
  /// Stable section identity.
  public let id: UUID
  /// Optional section header title (for example “Share to”).
  public var title: String?
  /// Actions displayed inside the group.
  public var actions: [FKActionSheetAction]

  /// Creates an action group.
  public init(
    id: UUID = UUID(),
    title: String? = nil,
    actions: [FKActionSheetAction]
  ) {
    self.id = id
    self.title = title
    self.actions = actions
  }
}
