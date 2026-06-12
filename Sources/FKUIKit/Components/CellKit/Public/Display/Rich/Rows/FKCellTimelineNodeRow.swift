import Foundation

/// ListKit-friendly row model for ``FKCellTimelineNodeCell``.
public struct FKCellTimelineNodeRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellTimelineNodeConfiguration

  /// Creates a timeline node row model.
  public init(id: String, configuration: FKCellTimelineNodeConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
