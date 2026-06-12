import Foundation

/// ListKit-friendly row model for ``FKFormCellSwitchCaptionCell``.
public struct FKFormSwitchCaptionRow: Sendable, Equatable, Hashable {
  public var id: String
  public var isOn: Bool
  public var configuration: FKFormCellSwitchCaptionConfiguration

  /// Creates a switch caption row model.
  public init(
    id: String,
    isOn: Bool = false,
    configuration: FKFormCellSwitchCaptionConfiguration
  ) {
    self.id = id
    self.isOn = isOn
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
