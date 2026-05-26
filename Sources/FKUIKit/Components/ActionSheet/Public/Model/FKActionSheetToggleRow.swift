import Foundation

/// Configuration for a standard row with a trailing `UISwitch`.
public struct FKActionSheetToggleRow: Equatable, Sendable {
  /// Whether the switch is on.
  public var isOn: Bool
  /// Table view reuse identifier.
  public var reuseIdentifier: String

  /// Creates toggle row configuration.
  public init(isOn: Bool, reuseIdentifier: String = "FKActionSheetToggleRow") {
    self.isOn = isOn
    self.reuseIdentifier = reuseIdentifier
  }
}
