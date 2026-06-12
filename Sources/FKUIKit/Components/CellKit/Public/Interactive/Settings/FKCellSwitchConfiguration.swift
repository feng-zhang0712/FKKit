import Foundation

/// Configuration for ``FKCellSwitchCell`` (I-01).
public struct FKCellSwitchConfiguration: Sendable, Equatable {
  public var title: String
  public var isOn: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a switch row configuration.
  public init(
    title: String,
    isOn: Bool = false,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.isOn = isOn
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
