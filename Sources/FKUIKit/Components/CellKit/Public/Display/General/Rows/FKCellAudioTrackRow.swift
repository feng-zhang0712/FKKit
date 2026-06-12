import Foundation

/// ListKit-friendly row model for ``FKCellAudioTrackCell`` (D-24).
public struct FKCellAudioTrackRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellAudioTrackConfiguration

  public init(id: String, configuration: FKCellAudioTrackConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
