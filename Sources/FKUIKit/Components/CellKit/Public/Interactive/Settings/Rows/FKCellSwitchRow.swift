import Foundation

/// ListKit-friendly row model for ``FKCellSwitchCell``.
public struct FKCellSwitchRow: Sendable, Equatable, Hashable {
  public var id: String
  public var title: String
  public var isOn: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a switch row model.
  public init(
    id: String,
    title: String,
    isOn: Bool = false,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.id = id
    self.title = title
    self.isOn = isOn
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }

  /// Converts to a cell configuration snapshot.
  public var configuration: FKCellSwitchConfiguration {
    FKCellSwitchConfiguration(
      title: title,
      isOn: isOn,
      isEnabled: isEnabled,
      separatorPolicy: separatorPolicy,
      isLastInSection: isLastInSection
    )
  }
}
