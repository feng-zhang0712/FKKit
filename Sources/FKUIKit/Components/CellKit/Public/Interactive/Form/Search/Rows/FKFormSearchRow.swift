import Foundation

/// ListKit-friendly row model for ``FKFormCellSearchCell``.
public struct FKFormSearchRow: Sendable, Equatable, Hashable {
  public var id: String
  public var text: String
  public var configuration: FKFormCellSearchConfiguration

  /// Creates a search row model.
  public init(
    id: String,
    text: String = "",
    configuration: FKFormCellSearchConfiguration
  ) {
    self.id = id
    self.text = text
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
