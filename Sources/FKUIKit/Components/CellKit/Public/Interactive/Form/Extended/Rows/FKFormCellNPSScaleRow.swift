import Foundation

/// ListKit-friendly row model for ``FKFormCellNPSScaleCell``.
public struct FKFormCellNPSScaleRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellNPSScaleConfiguration
  public var selectedScore: Int?

  public init(
    id: String,
    configuration: FKFormCellNPSScaleConfiguration,
    selectedScore: Int? = nil
  ) {
    self.id = id
    self.configuration = configuration
    self.selectedScore = selectedScore
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
