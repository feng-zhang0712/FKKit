import Foundation

/// ListKit-friendly row model for ``FKFormCellPINIndicatorCell``.
public struct FKFormCellPINIndicatorRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellPINIndicatorConfiguration
  public var filledCount: Int

  public init(
    id: String,
    configuration: FKFormCellPINIndicatorConfiguration,
    filledCount: Int = 0
  ) {
    self.id = id
    self.configuration = configuration
    self.filledCount = filledCount
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
