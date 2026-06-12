import Foundation

/// ListKit-friendly row model for ``FKCellRatingCell`` (D-52).
public struct FKCellRatingRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellRatingConfiguration

  public init(id: String, configuration: FKCellRatingConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
