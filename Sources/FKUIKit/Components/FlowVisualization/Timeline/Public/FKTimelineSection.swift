import Foundation

/// Grouped timeline rows with a section title.
public struct FKTimelineSection: Sendable, Equatable, Identifiable {
  /// Stable section identifier.
  public var id: String
  /// Section header text.
  public var title: String
  /// Rows in this section.
  public var items: [FKFlowStepItem]

  public init(id: String, title: String, items: [FKFlowStepItem]) {
    self.id = id
    self.title = title
    self.items = items
  }
}
