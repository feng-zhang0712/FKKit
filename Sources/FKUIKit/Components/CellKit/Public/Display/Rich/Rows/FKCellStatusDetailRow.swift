import Foundation

/// ListKit-friendly row model for ``FKCellStatusDetailCell``.
public struct FKCellStatusDetailRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellStatusDetailConfiguration

  public init(id: String, configuration: FKCellStatusDetailConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
