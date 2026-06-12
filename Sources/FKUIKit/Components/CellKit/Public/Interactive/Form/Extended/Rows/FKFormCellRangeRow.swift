import Foundation

/// ListKit-friendly row model for ``FKFormCellRangeCell``.
public struct FKFormCellRangeRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellRangeConfiguration
  public var minText: String
  public var maxText: String

  public init(
    id: String,
    configuration: FKFormCellRangeConfiguration,
    minText: String = "",
    maxText: String = ""
  ) {
    self.id = id
    self.configuration = configuration
    self.minText = minText
    self.maxText = maxText
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
