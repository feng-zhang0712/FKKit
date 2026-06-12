import Foundation

/// ListKit-friendly row model for ``FKCellTagCell`` (D-54).
public struct FKCellTagRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellTagConfiguration

  public init(id: String, configuration: FKCellTagConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
