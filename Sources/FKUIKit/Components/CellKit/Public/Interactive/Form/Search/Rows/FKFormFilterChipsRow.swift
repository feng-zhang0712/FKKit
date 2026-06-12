import Foundation

/// ListKit-friendly row model for ``FKFormCellFilterChipsCell``.
public struct FKFormFilterChipsRow: Sendable, Equatable, Hashable {
  public var id: String
  public var selectedIDs: Set<String>
  public var configuration: FKFormCellFilterChipsConfiguration

  /// Creates a filter chips row model.
  public init(
    id: String,
    selectedIDs: Set<String> = [],
    configuration: FKFormCellFilterChipsConfiguration
  ) {
    self.id = id
    self.selectedIDs = selectedIDs
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
