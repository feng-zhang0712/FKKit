import Foundation

/// ListKit-friendly row model for ``FKFormCellInlineWheelCell``.
public struct FKFormCellInlineWheelRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellInlineWheelConfiguration
  public var selectedIndex: Int

  public init(
    id: String,
    configuration: FKFormCellInlineWheelConfiguration,
    selectedIndex: Int = 0
  ) {
    self.id = id
    self.configuration = configuration
    self.selectedIndex = selectedIndex
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
