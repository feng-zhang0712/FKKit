import Foundation

/// ListKit-friendly row model for ``FKCellFilterSummaryCell`` (D-55).
public struct FKCellFilterSummaryRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellFilterSummaryConfiguration

  public init(id: String, configuration: FKCellFilterSummaryConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
